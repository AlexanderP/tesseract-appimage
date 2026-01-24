#!/bin/bash

DIR=$(pwd)
DOCKER_DIR=${DIR}/test
green() { echo -e "\\e[1;32m$1\\e[0;39;49m"; }
red() { echo -e "\\e[1;31m$1\\e[0;39;49m"; }
blue() { echo -e "\\e[1;34m$1\\e[0;39;49m"; }
green_n() { echo -en "\\e[1;32m$1\\e[0;39;49m"; }
DIST=("almalinux_8" \
      "almalinux_9" \
      "almalinux_10" \
      "alt_p10" \
      "alt_p11" \
      "debian_11" \
      "debian_12" \
      "debian_13" \
      "fedora_38" \
      "fedora_39" \
      "fedora_40" \
      "fedora_41" \
      "fedora_42" \
      "ubuntu_14.04" \
      "ubuntu_16.04" \
      "ubuntu_18.04" \
      "ubuntu_20.04" \
      "ubuntu_22.04" \
      "ubuntu_24.04" \
      "ubuntu_25.04" \
      "opensuse_15.3" \
      "opensuse_15.4" \
      "opensuse_15.5"\
      "opensuse_15.6"\
      "opensuse_tumbleweed"\
      "archlinux" \
      "fedora_43" \
      "opensuse_16.0" \
    )
PICTURE="Apache.gif Apache.jpg Apache.png Apache.tif Apache.webp"

create_images(){
    for _images in "${DIST[@]}" ; do
        if docker images | grep -q "tess_${_images}"
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
            echo -e "Проверка версии\n" >> "${log_file}"
            green_n "Проверка версии                    "
            docker_run "tess_${_images}" "${1}" -v
            green_n "Проверка списка языков             "
            echo -e "\nПроверка списка языков\n" >> "${log_file}"
            docker_run "tess_${_images}" "${1}" --list-langs
            for _picture in ${PICTURE}; do
                echo -e "\nПроверка распознавания ${_picture}\n" >> "${log_file}"
                green_n "Проверка распознавания ${_picture}  "
                docker_run "tess_${_images}" "${1}" ${_picture} -
            done
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
