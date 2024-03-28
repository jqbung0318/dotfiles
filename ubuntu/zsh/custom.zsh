# Docker & Docker compose
alias dockdown='f() { docker compose -f $1 down };f'
alias dockbuild='f() { docker compose -f $1 build ${@:2}};f'
alias dockup='f() { docker compose -f $1 up ${@:2}};f'
alias dockrun='f() { docker compose -f $1 run --rm ${@:2}};f'
alias docklazy='f() { docker compose -f $1 build && docker compose -f $1 down && docker compose -f $1 up ${@:2} };f'
alias dock="docker"
alias dockstats="docker stats --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'"
