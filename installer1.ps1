# Define the Node.js version
$nodeVersion = "v18.16.0"

# Define the URL for the Node.js installer
$nodeUrl = "https://nodejs.org/dist/$nodeVersion/node-$nodeVersion-x64.msi"

# Define the path to save the installer
$installerPath = "$env:TEMP\nodejs_installer.msi"

# Function to download Node.js installer
function Download-NodeInstaller {
    Write-Host "Downloading Node.js installer..."
    Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath
}

# Function to install Node.js
function Install-Node {
    Write-Host "Installing Node.js..."
    Start-Process msiexec.exe -ArgumentList "/i $installerPath /quiet /norestart" -NoNewWindow -Wait
    Write-Host "Node.js installed successfully."
}

# Function to install Lua using Node.js script
function Install-Lua {
    Write-Host "Installing Lua..."
    $nodeScript = @"
const { exec } = require('child_process');
const https = require('https');
const fs = require('fs');
const path = require('path');
const tar = require('tar');

const luaVersion = '5.4.4';
const luaTarballUrl = `https://www.lua.org/ftp/lua-\${luaVersion}.tar.gz`;
const luaTarballPath = path.join(__dirname, `lua-\${luaVersion}.tar.gz`);
const luaSourceDir = path.join(__dirname, `lua-\${luaVersion}`);

// Function to download the Lua tarball
function downloadLuaTarball() {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(luaTarballPath);
        https.get(luaTarballUrl, (response) => {
            response.pipe(file);
            file.on('finish', () => {
                file.close(resolve);
            });
        }).on('error', (err) => {
            fs.unlink(luaTarballPath);
            reject(err);
        });
    });
}

// Function to extract the tarball
function extractLuaTarball() {
    return tar.x({ file: luaTarballPath, cwd: __dirname });
}

// Function to compile and install Lua
function installLua() {
    return new Promise((resolve, reject) => {
        exec(`cd \${luaSourceDir} && make linux test && sudo make install`, (error, stdout, stderr) => {
            if (error) {
                reject(\`Error: \${error.message}\n\${stderr}\`);
                return;
            }
            resolve(stdout);
        });
    });
}

// Main function to orchestrate the download, extraction, and installation
async function main() {
    try {
        console.log('Downloading Lua...');
        await downloadLuaTarball();
        console.log('Extracting Lua...');
        await extractLuaTarball();
        console.log('Installing Lua...');
        const output = await installLua();
        console.log('Lua installed successfully:\n', output);
    } catch (error) {
        console.error('Installation failed:', error);
    }
}

main();
"@

    $nodeScriptPath = "$env:TEMP\install_lua.js"
    $nodeScript | Out-File -FilePath $nodeScriptPath -Encoding utf8

    # Install tar module
    npm install tar

    # Run the Node.js script
    node $nodeScriptPath
}

# Main script execution
Download-NodeInstaller
Install-Node

# Adding Node.js to PATH
$env:Path += ";$env:ProgramFiles\nodejs"
[System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

Install-Lua
