const fs = require('fs');
const path = require('path');
const prettier = require('prettier');

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
    // Remove single-line comments
    sourceCode = sourceCode.replace(/\/\/.*/g, '');
    
    // Remove multi-line comments
    sourceCode = sourceCode.replace(/\/\*[\s\S]*?\*\//g, '');
    
    // Remove JSDoc comments
    sourceCode = sourceCode.replace(/\/\*\*[\s\S]*?\*\//g, '');
    
    return sourceCode;
}

function removeConsoleLog(sourceCode) {
    return sourceCode.replace(/console\.log\([^)]*\);?/g, '');
}

async function processFile(filePath) {
    try {
        // Read the file
        let sourceCode = fs.readFileSync(filePath, 'utf8');
        
        // Remove comments first
        sourceCode = removeComments(sourceCode);
        
        // Remove console.log statements
        sourceCode = removeConsoleLog(sourceCode);
        
        // Format code using prettier
        const formattedCode = await prettier.format(sourceCode, {
            ...config.prettierConfig,
            filepath: filePath
        });
        
        // Write the processed code back to the file
        fs.writeFileSync(filePath, formattedCode);
        console.log(`✓ Processed: ${filePath}`);
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
