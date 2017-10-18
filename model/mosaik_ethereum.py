import mosaik_api
from web3 import Web3, HTTPProvider
import json

__version__ = '0.0.0'
meta = {
    'models': {
        'Ethereum': {
            'public': True,
            'any_inputs': True,
            'params': [],
            'attrs': ['load', 'gene'],
        },
    },
}

class Ethereum(mosaik_api.Simulator):
    def __init__(self):
        super().__init__(meta)
        self.step_size = None
        self.eids = []
        self.sid = None

        # blockchain parameters
        self.accounts = None
        self.contract = None
        self.contract_addr = None

    def init(self, sid, step_size):
        # Initialize some meta information about the model
        self.sid = sid
        self.step_size = step_size
        return self.meta

    def create(self, num, model):
        if model != 'Ethereum':
            raise ValueError('Invalid model "%s" % model')

        # Initialize the connection to the blockchain network
        self._init_network_connection()

        # Create instances of the model
        start_idx = len(self.eids)
        entities = []
        for i in range(num):
            # Transact to the blockchain to add a participant
            trans_hash = self.contract.transact(
                {'to': self.contract_addr, 'gas': 90000}).add_participant()

            # Normal Mosaik protocol
            eid = '%s_%s' % (model, i + start_idx)
            entities.append({
                'eid': eid,
                'type': model,
                'rel': [],
            })
            self.eids.append(eid)
        return entities

    def step(self, time, inputs=None):
        # # Calculate energy = power_for_timestep * 1 timestep / 1 hour [Wh] (15/60)
        # for eid, attrs in inputs.items():
        #     for attr, nodes in attrs.items():
        #         for node, value in nodes.items():
        #             set_value = value
        # import pdb; pdb.set_trace()


        # For all the participants on the blockchain
        for eid, attrs in inputs.items():
            # Pick account
            account = self.accounts[int(eid.split('_')[1])]

            # For all the attributes to post to the blockchain
            for attr, attr_data in attrs.items():

                # For all the sources of those attributes
                for source, value in attr_data.items():
                    if attr == 'load':
                        trans_hash = self.contract.transact(
                            {'to': self.contract_addr, 'gas': 90000}).addConsumptionToken(
                            account, int(abs(value)))
                    elif attr == 'gene':
                        trans_hash = self.contract.transact(
                            {'to': self.contract_addr, 'gas': 90000}).addGenerationToken(
                            account, int(abs(value)))
                    else:
                        raise ValueError('Invalid attr: ' + str(attr))

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
        network_id = list(energy_json['networks'].keys())[-1]
        self.contract_addr = energy_json['networks'][network_id]['address']

        # List accounts and set default account
        self.accounts = web3.eth.accounts
        web3.eth.defaultAccount = self.accounts[0]

        # Create reference to the contract
        self.contract = web3.eth.contract(energy_abi, self.contract_addr)


def main():
    return mosaik_api.start_simulation(Ethereum(), 'mosaik-ethereum simulator')
