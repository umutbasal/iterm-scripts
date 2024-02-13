targetsFileArg=$1
targetsFile=${targetsFileArg:-"hosts.txt"}
#echo {hosts[i]}
cmdArg=$2
cmd=${cmdArg:-"echo {hosts[i]}"}

# usage sh multi.sh hosts.txt 'echo {hosts[i]} | cat'
if [ ! -f $targetsFileArg ]; then
	echo "File $targetsFileArg not found!"
	echo "Usage: sh multi.sh hosts.txt 'echo {hosts[i]} | cat'"
	exit 1
fi

if [ -z "$cmdArg" ]; then
	echo "Command not found!"
	echo "Usage: sh multi.sh hosts.txt 'echo {hosts[i]} | cat'"
	exit 1
fi

#"host1", "host2", "host3", "host4", "host5", "host6", "host7", "host8", "host9", "host10"
hosts=$(awk '{printf "\"%s\", ", $0}' $targetsFile | sed 's/, $//')

script=$(cat <<'EOF'
#!/usr/bin/env python3.7

import iterm2

hosts = ["host1", "host2"]

async def main(connection):
    app = await iterm2.async_get_app(connection)
    window = app.current_terminal_window
    if window is not None:
        tab = window.current_tab

        k=0
        if ( len(hosts)-1) > 1:
            await tab.current_session.async_split_pane(vertical=False)
            for i in range(1, len(hosts)-1):
                if(len(hosts)-1)/2 > k:
                    await tab.sessions[0].async_activate()
                    await tab.current_session.async_split_pane(vertical=True)
                else:
                    await tab.sessions[k+1].async_activate()
                    await tab.current_session.async_split_pane(vertical=True)
                k+=1

        for i, sess in enumerate(tab.sessions):
            if i < len(hosts):
                await sess.async_send_text(f"echo {hosts[i]}\\\\n")
            else:
                break

    else:
        # You can view this message in the script console.
        print("No current window")

iterm2.run_until_complete(main)
EOF
)

sk=$(echo "$script" | sed "s/\"host1\", \"host2\"/$hosts/" | sed "s/echo {hosts\[i\]}/$cmd/")

echo "$sk" > ~/Library/Application\ Support/iTerm2/Scripts/multipane.py