# VS Code issue

Issue: `open $path` doesn't work if VS Code is launched from the command line (`code`).

This appears to happen when `code` references a different installation to the one registered under the UTI `com.microsoft.VSCode`.

To check the paths match:

```console
$ readlink -f $(which code)
/nix/store/sdpilqb5acr9y56gay9n04nfaad7wp9b-vscode-1.87.2/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code
$ duti -x ts
Visual Studio Code
/nix/store/sdpilqb5acr9y56gay9n04nfaad7wp9b-vscode-1.87.2/Applications/Visual Studio Code.app
com.microsoft.VSCode
```

If the paths don't match, try removing old generations:

```console
$ nix run nix-darwin -- --list-generations
$ nix-collect-garbage -d
$ # https://www.reddit.com/r/Nix/comments/12xqjt3/darwin_home_manger_and_nix_generations/
$ sudo nix-collect-garbage -d
```

You might also need to restart and repeat GC.
