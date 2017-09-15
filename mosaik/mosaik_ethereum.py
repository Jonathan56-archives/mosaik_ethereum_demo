import mosaik_api
from web3 import Web3, HTTPProvider
import json

__version__ = '0.0.0'


class Ethereum(mosaik_api.Simulator):
    def __init__(self):
        super().__init__({'models': {}})
        self.model_name = None
        self.step_size = None
        self.attrs = None
        self.eids = []

        # blockchain parameters
        self.accounts = None
        self.contract = None

    def init(self, sid, step_size):
        # Initialize some meta information about the model
        self.model_name = 'Ethereum'
        self.step_size = step_size
        self.attrs = ['Prod', 'Gen']
        self.meta['models'][self.model_name] = {
            'public': True,
            'params': [],
            'attrs': attrs,
        }
        return self.meta

    def create(self, num, model):
        if model != self.model_name:
            raise ValueError('Invalid model "%s" % model')

        # Initialize the connection to the blockchain network
        self._init_network_connection()

        # Create instances of the model
        start_idx = len(self.eids)
        entities = []
        for i in range(num):
            eid = '%s_%s' % (model, i + start_idx)
            entities.append({
                'eid': eid,
                'type': model,
                'rel': [],
            })
            self.eids.append(eid)
        return entities

    def step(self, time, inputs=None):
        # FIGURE OUT INPUT FORMAT
        print(inputs)
        import pdb; pdb.set_trace()

        # Interact with the blockchain network
        trans_hash = contract.transact(
            {'to': energy_address, 'gas': 90000}).addConsumptionToken(
            account[0], SOMEINPUTS)
        return time + self.step_size

    def get_data(self, outputs=None):
        # This model don't implement a get function - directly interact with
        # the blockchain to retrieve information
        data = {}
        return data

    def _init_network_connection(self):
        # Connect to the network
        web3 = Web3(HTTPProvider('http://localhost:8545'))

        # Get contract signature
        with open('ethereum/build/contracts/Energy.json') as energy_file:
            energy_json = json.load(energy_file)
        energy_abi = energy_json['abi']
        network_id = energy_json['networks'].keys()[-1]
        energy_address = energy_json['networks'][network_id]['address']

        # List accounts and set default account
        self.accounts = web3.eth.accounts
        web3.eth.defaultAccount = self.accounts[0]

        # Create reference to the contract
        self.contract = web3.eth.contract(energy_abi, energy_address)

        # Add a filter
        contract_filter = self.contract.on('addedRessource',
            filter_params={'fromBlock': 'earliest'})


def main():
    return mosaik_api.start_simulation(Ethereum(), 'mosaik-ethereum simulator')
