#!/bin/bash
#
#   Para utilizar este script, hay que añadir la URL de los repositorios que se considere que se han utilizado en el fichero repositories, hay que quitar la extensión .default si es la primera vez que se va a utilizar el script, en la misma ruta que este fichero .sh
#   Argumentos:  1.  Nombre distintivo para realizar la búsqueda (obligatorio).  La mejor opción es utilizar el inicio del correo (nombre.apellido1, por ejemplo).  No es case sensitive
#                2.  Opción para borrar los repositorios que no tienen commits de la lista [opcional].  Para activarlo hay que poner true.  Los repositorios eliminados se guardan
#                    en un fichero el path desde donde se ha ejecutado el script: EmptyRepositories
#
#   Los logs se guardan en $WORKSPACE/gitlogs divididos por Mes y Repositorio



set -euo pipefail

AUTHOR=$1
PULL=${2:-"true"}
DELETEREPO=${3:-"false"}

REPOSITORIES=$(cat repositories)
WORKSPACE="$(pwd)"

GITLAB_DIRECTORY="$WORKSPACE/gitlab"
GITLOGS_DIRECTORY="$WORKSPACE/gitlogs/raw"
mkdir -p "$GITLAB_DIRECTORY"
rm -rf "$GITLOGS_DIRECTORY"
mkdir -p "$GITLOGS_DIRECTORY"

PROGRESS_BAR_WIDTH=50

println() {
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    echo -e "[$dt] $1"
}

strindex() {
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

draw_progress_bar() {
  # Arguments: current value, max value
  local __value=$1
  local __max=${2:-$__value}

  # Calculate percentage
  if (( $__max < 1 )); then __max=1; fi  # anti zero division protection
  local __percentage=$(( 100 - ($__max*100 - $__value*100) / $__max ))

  # Rescale the bar according to the progress bar width
  local __num_bar=$(( $__percentage * $PROGRESS_BAR_WIDTH / 100 ))

  # Draw progress bar
  printf "["
  for b in $(seq 1 $__num_bar); do printf "#"; done
  for s in $(seq 1 $(( $PROGRESS_BAR_WIDTH - $__num_bar ))); do printf " "; done
  printf "] $__percentage%% ($__value / $__max)\r"
}


createEvidences() {
    echo
    git config --global credential.helper 'cache --timeout=9000'
    for urlrepo in $REPOSITORIES; do

        repositoryName=$(echo ${urlrepo##*/})

        ## Local or url?
        firstDot=$(strindex $urlrepo ".")
        firstSlash=$(strindex $urlrepo "/")
        if [ "$firstDot" = "0" ] || [ "$firstSlash" = "0" ]; then
            echo "Local repo $repositoryName"
            cd $WORKSPACE
            repositoryDir=$urlrepo
        else
            echo "Remote repo $repositoryName"
            cd $GITLAB_DIRECTORY
            repositoryDir=$repositoryName
        fi

        # Clone or pull
        if [ ! -d "$repositoryDir" ]; then
            println "Cloning repository $urlrepo "
            mkdir -p $repositoryDir
            cd $repositoryDir
            git clone -q $urlrepo.git .
        else
            println "Change directory $repositoryDir"
            cd $repositoryDir
            branch=$(git branch -a | grep -v "remotes" | grep -v detached | head -1 | tr -d "*" | awk '{print $1}')
            println "Pulling repository $repositoryName in branch $branch"
            git checkout -f -q $branch
            if [ "$PULL" = "true"  ]; then
                git pull -q
            fi
        fi

        Totalbranches=$(git branch -a | wc -l)
        println "Numbers of Branches in $repositoryName: $Totalbranches."
        println "Searching for commits..."
        repositoryCommitLog="$GITLOGS_DIRECTORY/${repositoryName}_commits.log"

        i=0
        for branch in $(git branch -a | sed 's|\*||g' | awk '{print $1}')
        do
            git checkout -f -q $branch
            git log --pretty=format:"%h%x09%cd%x09%cn%x09%s" -i --committer="${AUTHOR}" --no-merges | awk -v PROJECT=$repositoryName '{print $3" "$4 "\t" PROJECT "\t" $0}' | tail -r >> "${repositoryCommitLog}"
            draw_progress_bar $i $Totalbranches
            i=$(( i + 1 ))
        done

        draw_progress_bar $Totalbranches
        echo
        cat "${repositoryCommitLog}" | sort -u -o "${repositoryCommitLog}"
        TotalCommits=$(cat ${repositoryCommitLog} | wc -l)
        println "Repository $repositoryName Total commits: $TotalCommits"
        cd $GITLAB_DIRECTORY
        if [ "$TotalCommits" = "0"  ] && [ "$DELETEREPO" = "true"  ];then
            println "Removing $urlrepo from list"
            echo $urlrepo >> $WORKSPACE/EmptyRepositories
            cat $WORKSPACE/EmptyRepositories | sort -u -o $WORKSPACE/EmptyRepositories
            sed -i "\|^${urlrepo}$|d" $WORKSPACE/repositories
            rm -rf $GITLAB_DIRECTORY/$repositoryName
        else
        for MONTH in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
        do
            grep "^${MONTH}" "${repositoryCommitLog}" > "${WORKSPACE}/gitlogs/${MONTH}_${repositoryName}_commits.log" && echo -n "${MONTH} " || rm -f "${WORKSPACE}/gitlogs/${MONTH}_${repositoryName}_commits.log"
        done
        fi
        echo
    done
    cd $WORKSPACE
}

println "======================================="
createEvidences
println "======================================="
