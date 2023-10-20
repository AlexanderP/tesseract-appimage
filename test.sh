#!/bin/bash

DIR=$(pwd)
DOCKER_DIR=${DIR}/test
green() { echo -e "\\e[1;32m$1\\e[0;39;49m"; }
red() { echo -e "\\e[1;31m$1\\e[0;39;49m"; }
blue() { echo -e "\\e[1;34m$1\\e[0;39;49m"; }
green_n() { echo -en "\\e[1;32m$1\\e[0;39;49m"; }
DIST=("almalinux_8" \
      "almalinux_9" \
      "debian_10" \
      "debian_11" \
      "debian_12" \
      "fedora_29" \
      "fedora_30" \
      "fedora_31" \
      "fedora_32" \
      "fedora_33" \
      "fedora_34" \
      "fedora_35" \
      "fedora_36" \
      "fedora_37" \
      "fedora_38" \
      "ubuntu_20.04" \
      "ubuntu_22.04" \
      "ubuntu_23.04" \
      "ubuntu_23.10" \
      "opensuse_15.3" \
      "opensuse_15.4" \
      "opensuse_15.5"\
      "opensuse_tumbleweed" )


create_images(){
    for _images in "${DIST[@]}" ; do
        if docker images | grep -q "${_images}"
        then
            green "Образ ${_images} создан"
        else
            green "Создание образа ${_images}"
            cd "${DOCKER_DIR}/${_images}"  || exit 1
            docker build -t "tess_${_images}" .  || exit 1
        fi
    done
}

rm_images(){
    for _images in "${DIST[@]}" ; do
        if docker images | grep -q "${_images}"
        then
            green "Удаление образа ${_images}"
            docker image rm "tess_${_images}" || exit 1
        fi
    done
}

test_teseeract(){
    docker_run(){
        if [ "${TRUE}" -eq 1 ]
        then
            docker run --rm -v "$PWD:/build" \
                           --device=/dev/fuse \
                           --cap-add SYS_ADMIN \
                           --security-opt apparmor:unconfined \
                           "${@}" &>> "${log_file}"
            if [ $? -eq 0 ]; then
                green "[OK]"
            else
                red "[Ошибка]"
                TRUE=0
            fi
        else
            blue "[Пропуск]"
        fi
    }
    blue "${1}"
    for _images in "${DIST[@]}" ; do
        green   "               ${_images}              "
        green   "_______________________________________"
        TRUE=1
        log_file=/tmp/log_${_images}
        test ! -f "${log_file}" || rm "${log_file}" && touch "${log_file}"
        if docker images | grep -q "${_images}"
        then
            green_n "Проверка версии                    "
            docker_run "tess_${_images}" "${1}" -v
            green_n "Проверка списка языков             "
            docker_run "tess_${_images}" "${1}" --list-langs
            green_n "Проверка распознавания             "
            docker_run "tess_${_images}" "${1}" Apache.tif -
        else
            red "Образ ${_images} несуществует "
        fi
        unset TRUE
        echo ""
    done
}

#create_images
#rm_images
test_teseeract "$1"
