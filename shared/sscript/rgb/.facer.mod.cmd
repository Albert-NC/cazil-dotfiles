savedcmd_facer.mod := printf '%s\n'   facer.o | awk '!x[$$0]++ { print("./"$$0) }' > facer.mod
