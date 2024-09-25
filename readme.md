# Introduction

This repository holds the files I use for initializing a new machine and my PowerShell prompt.

## prompt

The theme for [oh-my-posh](https://ohmyposh.dev) can be found in the [oh-my-config.json](oh-my-config.json) file.

> This file is modified from Scott Hanselman's Gist here: [shanselman/ohmyposhv3-v2.json](https://gist.github.com/shanselman/1f69b28bfcc4f7716e49eb5bb34d7b2c)

End result in current version:

![image](https://user-images.githubusercontent.com/11204251/155899277-93522414-1009-49ed-b094-e3e856a27e88.png)

## Profile Setup

> Note: Set-ExecutionPolicy -Scope CurrentUser -Policy RemoteSigned

### Required Modules

I prefer to store modules under the AllUsers scope so those files are not constantly sync'd by OneDrive. The [init.ps1](init.ps1) script will handle a few things:

1. Installing [requiredmodules](requiredmodules.psd1)
1. Create an initial Secret vault called `myCredentials` **if it does not already exists**

> Run the following command in an elevated PowerShell session

```console
.\init.ps1
```

### Modify PowerShell Profile

> The PSReadLine customizations were modified from Scott Hanselman's profile Gist: [shanselman/Microsoft.PowerShell_profile.ps1](https://gist.github.com/shanselman/25f5550ad186189e0e68916c6d7f44c3)

After running the init process above, open your PowerShell profile (e.g., `notepad $profile`), and add the line below.

> Adjust the path based on where you cloned this repository to your local machine
```console
. c:\git\prompt\ps-profile.ps1
```

### Reminders

> Things I'll never remember every time I setup a new device/machine
Conda - SSL proxy issues, create `.condarc` with `ssl_verify: {path to PEM file}`

