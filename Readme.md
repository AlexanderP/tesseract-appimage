# Introduction
The tesseract-ocr AppImage is built on Debian 13, using Docker container that provides all the required up-to-date dependencies.

# Instruction
1. Download AppImage from [releases](https://github.com/AlexanderP/tesseract-appimage/releases) page
1. Open your terminal application, if not already open
1. Browse to the location of the AppImage
3. Make the AppImage executable:   
    `$ chmod a+x tesseract*.AppImage`
4. Run it:  
    `./tesseract*.AppImage -l eng page.tif page.txt`

# Building
1. Cloning a Git repository:   
    `git clone https://github.com/AlexanderP/tesseract-appimage.git`   
    `cd tesseract-appimage && git submodule update --init`   
    `cd tesseract && git submodule  update --init test`  
    `cd ..`
1. Create Docker image:   
    `docker build -t tess_buildenv .`
2. Run build.sh:   
    `docker run --rm -v $PWD:/build --device=/dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined tess_buildenv bash build.sh -l "spa fin por fra rus deu"`
3. Run AppImage:   
    `./tesseract*.AppImage Apache.tif -`
