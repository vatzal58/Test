const fs = require('fs');
const path = require('path');
const prettier = require('prettier');
const typescript = require('typescript');

// Configuration
const config = {
    // File extensions to process
    extensions: ['.ts', '.tsx', '.js', '.jsx'],
    // Directories to exclude
    excludeDirs: ['node_modules', 'build', 'dist', '.git'],
    // Prettier configuration
    prettierConfig: {
        semi: true,
        trailingComma: 'es5',
        singleQuote: true,
        printWidth: 80,
        tabWidth: 2,
        parser: 'typescript'
    }
};

function removeConsoleLog(sourceCode) {
    // Remove only console.log statements
    const consoleLogRegex = /console\.log\((.*?)\);?/g;
    return sourceCode.replace(consoleLogRegex, '');
}

function removeComments(sourceCode) {
    // Use TypeScript compiler to remove comments
    const result = typescript.transpileModule(sourceCode, {
        compilerOptions: {
            removeComments: true,
            target: typescript.ScriptTarget.ESNext
        }
    });
    
    return result.outputText;
}

async function formatCode(sourceCode) {
    try {
        // Format the code using Prettier
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
        
        // Remove comments
        let processedCode = removeComments(sourceCode);
        
        // Remove console.log statements only
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
            // Skip excluded directories
            if (!config.excludeDirs.includes(file)) {
                walkDirectory(filePath);
            }
        } else if (stats.isFile()) {
            // Process only files with specified extensions
            const ext = path.extname(file);
            if (config.extensions.includes(ext)) {
                processFile(filePath);
            }
        }
    });
}

// Main execution
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
