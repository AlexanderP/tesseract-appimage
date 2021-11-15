#!/bin/bash
DIR=$(pwd)
REPS_DIR=${DIR}/work/reps
BUILD_DIR=${DIR}/work/build
GIT_URL="https://github.com/tesseract-ocr/tesseract.git"
SCRIPT_TESSDATA=("Arabic" "Armenian" "Bengali" "Canadian_Aboriginal" \
                 "Cherokee" "Cyrillic" "Devanagari" "Ethiopic" "Fraktur" \
                 "Georgian" "Greek" "Gujarati" "Gurmukhi" "Hangul_vert" \
                 "Hangul" "HanS_vert" "HanS" "HanT_vert" "HanT" "Hebrew" \
                 "Japanese_vert" "Japanese" "Kannada" "Khmer" "Lao" \
                 "Latin" "Malayalam" "Myanmar" "Oriya" "Sinhala" "Syriac" \
                 "Tamil" "Telugu" "Thaana" "Thai" "Tibetan" "Vietnamese")
LANG_TESSDATA=("afr" "amh" "ara" "asm" "aze_cyrl" "aze" "bel" "ben" "bod" \
               "bos" "bre" "bul" "cat" "ceb" "ces" "chi_sim_vert" "chi_sim" \
               "chi_tra_vert" "chi_tra" "chr" "cos" "cym" "dan" "deu" "div" \
               "dzo" "ell" "eng" "enm" "epo" "equ" "est" "eus" "fao" "fas" \
               "fil" "fin" "fra" "frk" "frm" "fry" "gla" "gle" "glg" "grc" \
               "guj" "hat" "heb" "hin" "hrv" "hun" "hye" "iku" "ind" "isl" \
               "ita_old" "ita" "jav" "jpn_vert" "jpn" "kan" "kat_old" "kat" \
               "kaz" "khm" "kir" "kmr" "kor_vert" "kor" "lao" "lat" "lav" \
               "lit" "ltz" "mal" "mar" "mkd" "mlt" "mon" "mri" "msa" "mya" \
               "nep" "nld" "nor" "oci" "ori" "osd" "pan" "pol" "por" "pus" \
               "que" "ron" "rus" "san" "sin" "slk" "slv" "snd" "spa_old" \
               "spa" "sqi" "srp_latn" "srp" "sun" "swa" "swe" "syr" "tam" \
               "tat" "tel" "tgk" "tha" "tir" "ton" "tur" "uig" "ukr" "urd" \
               "uzb_cyrl" "uzb" "vie" "yid" "yor")
INSTALL_TESSDATA=("eng" "osd")
BRANCH="master"


get_tessdata(){
    if test ! -f "${1}.traineddata"
    then
        if printf '%s\n' "${LANG_TESSDATA[@]}" | grep -q "^${1}$"
        then
            wget -c "https://github.com/tesseract-ocr/tessdata_fast/raw/main/${1}.traineddata"
        elif printf '%s\n' "${SCRIPT_TESSDATA[@]}" | grep -q "^${1}$"
        then
            wget -c "https://github.com/tesseract-ocr/tessdata_fast/raw/main/script/${1}.traineddata"
        else
            echo "Неизвестный файл - ${1}.traineddata"
            exit 1
        fi
    fi
}

while getopts "l:n" Option
do
    case $Option in
        l) 
        for _lang in $OPTARG
        do
            if printf '%s\n' "${LANG_TESSDATA[@]}" | grep -q "^${_lang}$"
            then
                INSTALL_TESSDATA=( "${INSTALL_TESSDATA[@]}" "${_lang}")
            elif printf '%s\n' "${SCRIPT_TESSDATA[@]}" | grep -q "^${_lang}$"
            then
                INSTALL_TESSDATA=( "${INSTALL_TESSDATA[@]}" "${_lang}")
            elif echo "all" | grep -q "^${_lang}$"
            then
                INSTALL_TESSDATA=("${SCRIPT_TESSDATA[@]}" "${LANG_TESSDATA[@]}")
            else
                echo "Неизвестный traineddata файл - ${_lang}"
                exit 1
            fi
        done
        ;;
        n) BUILD="False" ;;
    esac
done
shift $((OPTIND - 1))

BRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/^\* //')

case ${BRANCH} in
    4.x)
        _TESSDATA_PREFIX=/usr/share/tesseract-ocr/4.00
    ;;
    *)
        _TESSDATA_PREFIX=/usr/share/tesseract-ocr/5
    ;;
esac

test -d "${REPS_DIR}" || mkdir -p "${REPS_DIR}"
test -d "${BUILD_DIR}" || mkdir -p "${BUILD_DIR}"

cd "${REPS_DIR}" || exit 1
test -d "${REPS_DIR}/lang" || mkdir -p "${REPS_DIR}/lang"
cd "${REPS_DIR}/lang" || exit 1
for _lang in "${INSTALL_TESSDATA[@]}"
do
    get_tessdata "${_lang}"
done

cd "${DIR}/tesseract" || exit 1
VERSION="$(git describe --abbrev=4)"
export VERSION


if [[ ${BUILD} == "False" ]]
then
    cd "${BUILD_DIR}/tesseract" || exit 1
    test -f Makefile || exit 1
else
    rm -rf "${BUILD_DIR}/tesseract"
    cd "${BUILD_DIR}" || exit 1
    cp -r "${DIR}/tesseract" ${BUILD_DIR}/ || exit 1
    cd tesseract || exit 1
    CFLAGS="$(dpkg-buildflags --get CFLAGS) -Wall -g \
                -fPIC -DTESSDATA_PREFIX=${_TESSDATA_PREFIX}"
    LDFLAGS=$(dpkg-buildflags --get LDFLAGS)
    DEB_HOST_GNU_TYPE=$(dpkg-architecture -qDEB_HOST_GNU_TYPE)
    DEB_BUILD_GNU_TYPE=$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)
    export CFLAGS LDFLAGS DEB_HOST_GNU_TYPE DEB_BUILD_GNU_TYPE
    echo ${VERSION} > VERSION
    ./autogen.sh
    ./configure --host="${DEB_HOST_GNU_TYPE}" \
                --build="${DEB_BUILD_GNU_TYPE}" \
                --disable-tessdata-prefix --prefix=/usr \
                --mandir=/usr/share/man \
                --infodir=/usr/share/info \
                CXXFLAGS="${CFLAGS}" LDFLAGS="-llept -Wl,-z,defs ${LDFLAGS}"
    make -j10
fi

TESSDATA_PREFIX=${REPS_DIR}/lang
export TESSDATA_PREFIX
case ${BRANCH} in
    4.x)
        ./src/api/tesseract -v || exit 1
        ./src/api/tesseract ./test/testing/phototest.tif - || exit 1
    ;;
    *)
        ./tesseract -v || exit 1
        ./tesseract ./test/testing/phototest.tif - || exit 1
    ;;
esac
unset TESSDATA_PREFIX

if test ! -f linuxdeployqt-7-x86_64.AppImage
then
    wget -c "https://github.com/probonopd/linuxdeployqt/releases/download/7/linuxdeployqt-7-x86_64.AppImage"
    chmod a+x linuxdeployqt-7-x86_64.AppImage
fi

test ! -d AppDir || rm -rf AppDir
make install DESTDIR="$(pwd)/AppDir"

rm -rf AppDir/usr/include AppDir/usr/lib/pkgconfig \
       AppDir/usr/lib/*.la AppDir/usr/lib/*.a

mkdir -p AppDir${_TESSDATA_PREFIX}
mv AppDir/usr/share/tessdata AppDir${_TESSDATA_PREFIX}
for _lang in "${INSTALL_TESSDATA[@]}"
do
    cp "${REPS_DIR}/lang/${_lang}.traineddata" \
    "AppDir${_TESSDATA_PREFIX}/tessdata"
done
mkdir -p AppDir/usr/share/doc/tesseract-ocr || exit 1
cp AUTHORS LICENSE AppDir/usr/share/doc/tesseract-ocr/ || exit 1

unset QTDIR; unset QT_PLUGIN_PATH ; unset LD_LIBRARY_PATH

cat >> "AppDir/tesseract-env.desktop" << EOF
[Desktop Entry]
Type=Application
Name=tesseract
Icon=tesseract
Exec=tesseract
Terminal=true
StartupNotify=true
Categories=Office;
EOF

cp "${DIR}/tesseract.png" "AppDir/"

cat >> "AppDir/AppRun" << EOF
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\${0}")")"

export LD_LIBRARY_PATH=\${HERE}/usr/lib:\$LD_LIBRARY_PATH

if [ -z "\$TESSDATA_PREFIX" ]
then
    export TESSDATA_PREFIX=\${HERE}${_TESSDATA_PREFIX}/tessdata
fi

if [ ! -z \$APPIMAGE ] ; then
  BINARY_NAME=\$(basename "\$ARGV0")
else
  BINARY_NAME=\$(basename "\$0")
fi

exec "\${HERE}/usr/bin/tesseract" "\$@"
EOF

chmod +x AppDir/AppRun

LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:$(pwd)/AppDir/usr/lib"
export LD_LIBRARY_PATH

./linuxdeployqt-7-x86_64.AppImage AppDir/tesseract-env.desktop -appimage

cp tesseract-${VERSION}-x86_64.AppImage ${DIR}
