const fs = require('fs');
const path = require('path');
const prettier = require('prettier');
const ts = require('typescript');

// Configuration
const config = {
    extensions: ['.ts', '.tsx', '.js', '.jsx'],
    excludeDirs: ['node_modules', 'build', 'dist', '.git'],
    prettierConfig: {
        semi: true,
        trailingComma: 'es5',
        singleQuote: true,
        printWidth: 80,
        tabWidth: 2,
        parser: 'typescript'
    }
};

function removeComments(sourceCode) {
    // Create a source file
    const sourceFile = ts.createSourceFile(
        'temp.ts',
        sourceCode,
        ts.ScriptTarget.Latest,
        true
    );

    // Transformer factory to remove comments
    const transformerFactory = (context) => {
        return (sourceFile) => {
            const visitor = (node) => {
                // Remove JSDoc comments and trailing comments
                const newNode = ts.setEmitFlags(
                    ts.getMutableClone(node),
                    ts.EmitFlags.NoComments | ts.EmitFlags.NoTrailingComments
                );
                return ts.visitEachChild(newNode, visitor, context);
            };
            return ts.visitNode(sourceFile, visitor);
        };
    };

    // Create printer
    const printer = ts.createPrinter({
        removeComments: true,
        newLine: ts.NewLineKind.LineFeed
    });

    // Transform and print
    const result = ts.transform(sourceFile, [transformerFactory]);
    const transformedSourceFile = result.transformed[0];
    
    return printer.printFile(transformedSourceFile);
}

function removeConsoleLog(sourceCode) {
    // Remove console.log statements
    const consoleLogRegex = /console\.log\((.*?)\);?\n?/g;
    return sourceCode.replace(consoleLogRegex, '');
}

async function formatCode(sourceCode) {
    try {
        const formattedCode = await prettier.format(sourceCode, config.prettierConfig);
        return formattedCode;
    } catch (error) {
        console.error('Error formatting code:', error);
        return sourceCode;
    }
}

function processFile(filePath) {
    try {
        // Read the file
        const sourceCode = fs.readFileSync(filePath, 'utf8');
        
        // Process the code
        let processedCode = sourceCode;
        
        try {
            // Remove comments
            processedCode = removeComments(processedCode);
        } catch (commentError) {
            console.warn(`Warning: Could not remove comments from ${filePath}:`, commentError);
        }
        
        // Remove console.log statements
        processedCode = removeConsoleLog(processedCode);
        
        // Format the code
        formatCode(processedCode).then(formattedCode => {
            // Write the processed code back to the file
            fs.writeFileSync(filePath, formattedCode);
            console.log(`✓ Processed: ${filePath}`);
        });
    } catch (error) {
        console.error(`Error processing ${filePath}:`, error);
    }
}

function walkDirectory(dir) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
        const filePath = path.join(dir, file);
        const stats = fs.statSync(filePath);
        
        if (stats.isDirectory()) {
            if (!config.excludeDirs.includes(file)) {
                walkDirectory(filePath);
            }
        } else if (stats.isFile()) {
            const ext = path.extname(file);
            if (config.extensions.includes(ext)) {
                processFile(filePath);
            }
        }
    });
}

function main() {
    const projectDir = process.argv[2] || '.';
    
    console.log('Starting code cleanup...');
    console.log('Project directory:', projectDir);
    
    try {
        walkDirectory(projectDir);
        console.log('\nCode cleanup completed successfully!');
    } catch (error) {
        console.error('Error during code cleanup:', error);
        process.exit(1);
    }
}

main();
