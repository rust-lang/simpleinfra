const process = require('process')

// Third Party libraries
const actions = require('@actions/core')
const exec = require('@actions/exec')

// Configuration
const checkFmt = actions.getInput('check_fmt') || false

async function main () {
  try {
    if (checkFmt) {
      try {
        await exec.exec('which', 'rustfmt')
      } catch {
        await exec.exec('rustup', ['component', 'add', 'rustfmt'])
      }
      await exec.exec('cargo', ['fmt', '--check'])
    }

    await exec.exec('cargo', ['build', '--workspace'])
    await exec.exec('cargo', ['test', '--workspace'])
  } catch (error) {
    console.log(error)
    process.exit(1)
  }
}

main()
