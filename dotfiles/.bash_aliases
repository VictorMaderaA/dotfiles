# Aliases
alias dc='docker compose'
alias dr='dc run --rm'
alias dcu='dc up'
alias siteup='dc up -d site'
alias sitedown='dc down'
alias migrate='dr artisan db:wipe && dr artisan migrate:refresh'
alias seed='dr artisan db:seed'
alias data='migrate && seed'
alias comp='dr composer install'
alias commit='git add . && git commit'
alias runtest='dr php vendor/bin/phpunit'
alias dockerprune='docker image prune -a -f && docker container prune -f && docker volume prune -f  && docker network prune -f  && docker system prune -f'
alias dockerstop='docker stop $(docker ps -a -q)'
alias dopen='nautilus --browser $(pwd)'
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'

#alias vpngelt='cd ~/openvpngelt/ && openvpn3 session-start --config gelt.ovpn'
alias vpnclose='pgrep openvpn | xargs sudo kill -9'
alias vpnstatus='openvpn3 sessions-list'

alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'


# ----------------------------------------------------------------
# ----------------------------------------------------------------
#  _____                 _   _                 
# |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
# | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
# |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
# |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
# ----------------------------------------------------------------
# ----------------------------------------------------------------

# Convert video to mp3 file
# UseCase: When you want to extract the audio from a video file
# $1 = input file, $2 = output file (exa: video.mp4, audio.mp3)
videotomp3() {
    ffmpeg -i $1 -vn -acodec libmp3lame -ac 2 -qscale:a 4 -ar 48000 $2
}

# Search in git history. Example: gitsearch "search term"
# UseCase: When you want to find a specific change in the git history like a variable name or a function name
# $1 = search term
gitsearch() {
    git log -S $1 --source --all
}

# Open a bash session in a running container. Example: dockerbash container_name
# UseCase: When you want to run a command inside a container but you don't want to install bash in the container
# $1 = container name
dockerbash() {
    docker exec -it $1 /bin/bash
}