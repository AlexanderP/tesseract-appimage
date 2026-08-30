#!/bin/bash

DOCKER_DIR="$(pwd)/test"
if [ ! -d "${DOCKER_DIR}" ]; then
    red "Директория ${DOCKER_DIR} не существует"
    exit 1
fi

if [ -t 1 ]; then
    green() { echo -e "\\e[1;32m$1\\e[0;39;49m"; }
    red() { echo -e "\\e[1;31m$1\\e[0;39;49m"; }
    blue() { echo -e "\\e[1;34m$1\\e[0;39;49m"; }
    green_n() { echo -en "\\e[1;32m$1\\e[0;39;49m"; }
else
    red() { echo "$1"; }
    blue() { echo "$1"; }
    green() { echo "$1"; }
    green_n() { echo -n "$1"; }
fi


DIST=("almalinux_8" \
      "almalinux_9" \
      "almalinux_10" \
      "alt_p10" \
      "alt_p11" \
      "debian_11" \
      "debian_12" \
      "debian_13" \
      "fedora_42" \
      "ubuntu_14.04" \
      "ubuntu_16.04" \
      "ubuntu_18.04" \
      "ubuntu_20.04" \
      "ubuntu_22.04" \
      "ubuntu_24.04" \
      "opensuse_15.6" \
      "opensuse_tumbleweed" \
      "archlinux" \
      "fedora_43" \
      "fedora_44" \
      "ubuntu_26.04" \
      "opensuse_16.0" \
    )
PICTURES=("Apache.gif" "Apache.jpg" "Apache.png" "Apache.tif" "Apache.webp")

if ! command -v docker &>/dev/null; then
    red "Docker не установлен"
    exit 1
fi

create_images(){
    for _images in "${DIST[@]}" ; do
        if docker image inspect "tess_${_images}" &>/dev/null
        then
            green "Образ ${_images} создан"
        else
            green "Создание образа ${_images}"
            docker build -t "tess_${_images}" "${DOCKER_DIR}/${_images}" || { red "Ошибка сборки образа ${_images}"; exit 1; }
        fi
    done
}

rm_images(){
    for _images in "${DIST[@]}" ; do
        if docker image inspect "tess_${_images}" &>/dev/null
        then
            green "Удаление образа ${_images}"
            docker image rm "tess_${_images}" || exit 1
        fi
    done
}

test_tesseract(){
    docker_run(){
        if [ "${FAIL_TRUE}" -eq 1 ]
        then
            timeout 300 docker run --rm -v "$PWD:/build" \
                           --device=/dev/fuse \
                           --cap-add SYS_ADMIN \
                           --security-opt apparmor:unconfined \
                           "${@}" &>> "${log_file}"
            if [ $? -eq 0 ]; then
                green "[OK]"
            else
                red "[Ошибка]"
                FAIL_TRUE=0
            fi
        else
            blue "[Пропуск]"
        fi
    }
    blue "${1}"
    for _images in "${DIST[@]}" ; do
        green   "               ${_images}              "
        green   "_______________________________________"
        FAIL_TRUE=1
        log_file=/tmp/log_${_images}
        > "${log_file}"
        if docker image inspect "tess_${_images}" &>/dev/null
        then
            echo -e "Проверка версии" >> "${log_file}"
            green_n "Проверка версии                    "
            docker_run "tess_${_images}" "${1}" -v
            green_n "Проверка списка языков             "
            echo -e "Проверка списка языков" >> "${log_file}"
            docker_run "tess_${_images}" "${1}" --list-langs
            for _picture in "${PICTURES[@]}"; do
                echo -e "Проверка распознавания ${_picture}" >> "${log_file}"
                green_n "Проверка распознавания ${_picture}  "
                docker_run "tess_${_images}" "${1}" ${_picture} -
            done
        else
            red "Образ ${_images} несуществует "
        fi
        unset FAIL_TRUE
        echo ""
    done
}

case "${1}" in
    create) create_images ;;
    remove) rm_images ;;
    test)   test_tesseract "${2:-tesseract}" ;;
    *)      echo "Usage: $0 {create|remove|test} [tesseract.appimage]"; exit 1 ;;
esac
