# Mosaik demo running an Ethereum node

Goals:
1 - Explore Mosaik's simulation platform (compare to the FMI standard)
2 - Run an Ethereum network and interface with it in Python
3 - Test research ideas around decentralized grid controls and energy market

## Ethereum

Dependencies: testrpc, truffle
1 - $ testrpc
2 - $ truffle compile & truffle migrate --reset
3 - $ jupyter notebook

Note: after deploying your contract on multiple testrpc networks you might want
to remove "contracts/Energy.json". The "network" field seems to accumulate network ids.
The file will be rebuild/reset next time you compile and migrate.

## Mosaik

Dependencies: running python 3 and requirements.txt
1 - $ python demo.py
