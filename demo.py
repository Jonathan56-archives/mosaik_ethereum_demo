import itertools
import random
from mosaik.util import connect_randomly, connect_many_to_one
import mosaik


sim_config = {
    'CSV': {
        'python': 'mosaik_csv:CSV',
    },
    'DB': {
        'cmd': 'mosaik-hdf5 %(addr)s',
    },
    'HouseholdSim': {
        'python': 'householdsim.mosaik:HouseholdSim',
        # 'cmd': 'mosaik-householdsim %(addr)s',
    },
    'PyPower': {
        'python': 'mosaik_pypower.mosaik:PyPower',
        # 'cmd': 'mosaik-pypower %(addr)s',
    },
    'WebVis': {
        'cmd': 'mosaik-web -s 0.0.0.0:8000 %(addr)s',
    },
    'Ethereum': {
        'python': 'model.mosaik_ethereum:Ethereum'
    },
}

START = '2014-01-01 00:00:00'
END = 1 * 24 * 3600  # 1 day -- originaly 31
PV_DATA = 'data/pv_10kw.csv'
PROFILE_FILE = 'data/profiles.data.gz'
GRID_NAME = 'demo_lv_grid'
GRID_FILE = 'data/%s.json' % GRID_NAME


def main():
    random.seed(23)
    world = mosaik.World(sim_config)
    create_scenario(world)
    # world.run(until=END)  # As fast as possilbe
    world.run(until=END, rt_factor=1/(60 * 15))  # Real-time 15min -> 1sec


def create_scenario(world):
    # Start simulators
    pypower = world.start('PyPower', step_size=15*60)
    hhsim = world.start('HouseholdSim')
    pvsim = world.start('CSV', sim_start=START, datafile=PV_DATA)
    ethereum_sim = world.start('Ethereum', step_size=15*60)

    # Instantiate models
    grid = pypower.Grid(gridfile=GRID_FILE).children
    houses = hhsim.ResidentialLoads(sim_start=START,
                                    profile_file=PROFILE_FILE,
                                    grid_name=GRID_NAME).children
    pvs = pvsim.PV.create(20)
    ethereum = ethereum_sim.Ethereum.create(1)

    # Connect entities
    connect_buildings_to_grid(world, houses, pvs, grid)

    # Database
    db = world.start('DB', step_size=60, duration=END)
    hdf5 = db.Database(filename='demo.hdf5')
    connect_many_to_one(world, houses, hdf5, 'P_out')
    connect_many_to_one(world, pvs, hdf5, 'P')

    nodes = [e for e in grid if e.type in ('RefBus, PQBus')]
    connect_many_to_one(world, nodes, hdf5, 'P', 'Q', 'Vl', 'Vm', 'Va')

    branches = [e for e in grid if e.type in ('Transformer', 'Branch')]
    connect_many_to_one(world, branches, hdf5,
                        'P_from', 'Q_from', 'P_to', 'P_from')

    # Ethereum "database"
    world.connect(nodes[0], ethereum[0], 'P')

    # Web visualization
    webvis = world.start('WebVis', start_date=START, step_size=60)
    webvis.set_config(ignore_types=['Topology', 'ResidentialLoads', 'Grid',
                                    'Database'])
    vis_topo = webvis.Topology()

    connect_many_to_one(world, nodes, vis_topo, 'P', 'Vm')
    webvis.set_etypes({
        'RefBus': {
            'cls': 'refbus',
            'attr': 'P',
            'unit': 'P [W]',
            'default': 0,
            'min': 0,
            'max': 30000,
        },
        'PQBus': {
            'cls': 'pqbus',
            'attr': 'Vm',
            'unit': 'U [V]',
            'default': 230,
            'min': 0.99 * 230,
            'max': 1.01 * 230,
        },
    })

    connect_many_to_one(world, houses, vis_topo, 'P_out')
    webvis.set_etypes({
        'House': {
            'cls': 'load',
            'attr': 'P_out',
            'unit': 'P [W]',
            'default': 0,
            'min': 0,
            'max': 3000,
        },
    })

    connect_many_to_one(world, pvs, vis_topo, 'P')
    webvis.set_etypes({
        'PV': {
            'cls': 'gen',
            'attr': 'P',
            'unit': 'P [W]',
            'default': 0,
            'min': -10000,
            'max': 0,
        },
    })


def connect_buildings_to_grid(world, houses, pvs, grid):
    # Get all bus with PQBus in a dictionnary {id: bus element}
    buses = filter(lambda e: e.type == 'PQBus', grid)
    buses = {b.eid.split('-')[1]: b for b in buses}

    # Get the node id for each house
    house_data = world.get_data(houses, 'node_id')

    # Assign node and buildings (pv + house)
    for index, house in enumerate(houses):
        node_id = house_data[house]['node_id']
        if index < len(pvs):
            world.connect(pvs[index], buses[node_id], 'P')
        world.connect(house, buses[node_id], ('P_out', 'P'))


if __name__ == '__main__':
    main()
