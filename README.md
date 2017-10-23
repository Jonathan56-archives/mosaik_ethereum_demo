# Mosaik demo running an Ethereum node

Goals:
- Explore Mosaik's simulation platform (compare to the FMI standard)
- Run an Ethereum network and interface with it in Python
- Test research ideas around decentralized grid controls and energy market

## Ethereum

Dependencies: testrpc, truffle
- $ testrpc
- $ rm build/contracts/Market.json & truffle compile & truffle migrate --reset
- $ jupyter notebook

Note: after deploying your contract on multiple testrpc networks you might want
to remove "contracts/Energy.json". The "network" field seems to accumulate network ids.
The file will be rebuild/reset next time you compile and migrate.

## Mosaik

Dependencies: running python 3 and requirements.txt
- $ python demo.py
