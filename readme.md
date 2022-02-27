# Introduction

This repository holds the files I use for initializing a new machine and my PowerShell prompt.

## prompt

The theme found in this repository was modified from Scott Hanselman's Gist here: [shanselman/ohmyposhv3-v2.json](https://gist.github.com/shanselman/1f69b28bfcc4f7716e49eb5bb34d7b2c)

End result in current version:

![image](https://user-images.githubusercontent.com/11204251/155899277-93522414-1009-49ed-b094-e3e856a27e88.png)

## Profile

A large portion of the PSReadLine customizations found in the profile were modified from Scott Hanselman's profile Gist here: [shanselman/Microsoft.PowerShell_profile.ps1](https://gist.github.com/shanselman/25f5550ad186189e0e68916c6d7f44c3)

## Required Modules

I prefer to store modules under the AllUsers scope so those files are not constantly sync'd by OneDrive. The [init.ps1](init.ps1) script will handle a few things:

1. Installing [requiredmodules](requiredmodules.psd1)
1. Create an initial Secret vault called `myCredentials` **if it does not already exists**

> Run the following command in an elevated PowerShell session

```powershell
.\init.ps1
```
