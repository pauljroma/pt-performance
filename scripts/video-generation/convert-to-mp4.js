const renderLottie = require('puppeteer-lottie');
const path = require('path');

async function main() {
    const inputPath = path.resolve(__dirname, 'bench-press.json');
    const outputPath = path.resolve(__dirname, 'bench-press-animated.mp4');
    
    console.log('Converting Lottie to MP4...');
    console.log('Input:', inputPath);
    console.log('Output:', outputPath);
    
    try {
        await renderLottie({
            path: inputPath,
            output: outputPath,
            width: 1080,
            height: 1080,
        });
        console.log('Conversion successful!');
        console.log('Output file:', outputPath);
    } catch (error) {
        console.error('Conversion failed:', error.message);
        process.exit(1);
    }
}

main();
