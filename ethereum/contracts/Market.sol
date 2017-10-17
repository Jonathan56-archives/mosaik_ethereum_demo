pragma solidity ^0.4.4;


contract Market {
  // Participant addresses
  address[] public participants;

  // Last energy balance per participant [kWh]
  mapping (address => uint) energy_balance;

  // Total production [kWh]
  uint total_production = 0;

  // Total consumption [kWh]
  uint total_consumption = 0;

  // Total number of participants
  uint number_of_participant = 10;

  // Number of participation during a round
  uint number_of_participation = 0;

  // Retail price [$/kWh]
  uint retail_price = 100;

  // Retail price upper limit [%]
  uint upper_ratio = 166;

  // Retail price lower limit [%]
  uint lower_ratio = 50;

  // Buying price [$/kWh]
  uint buying_price = 0;

  // Selling price [$/kWh]
  uint selling_price = 0;

  // Maximum / minimum local selling price
  uint maximum_local_selling_price = (3 * retail_price) / 2;
  uint minimum_local_selling_price = retail_price / 2;

  // Minimum local buying price
  uint minimum_local_buying_price = retail_price / 2;

  // Bill per participant [$]
  mapping (address => uint) bill;

  /* **********
      Event
  *********** */

  // NOT IMPLEMENTED YET

  /* **********
    Function
  *********** */

  // Add a participant to the market
  function add_participant(){
    // Add the address of the participant to the "phone book"
    participants.push(msg.sender);

    // Set participant bill to zero
    bill[msg.sender] = 0;
  }

  // Remove a participant from the market
  function remove_participant() {
    // NOT IMPLEMENTED YET
  }

  // Broadcast energy balance
  function post_energy_balance(uint amount) {
    // Set participant last energy balance
    energy_balance[msg.sender] = amount;

    // Increase total production or consumption
    if (amount > 0)
      // ratio need to be a positive number, so we ABS(amount)
      total_production += - amount;
    else
      total_consumption += amount;

    // Increase number of participant for the market round
    number_of_participation += 1;
  }

  // Clear the market (set the prices and send bills)
  function clear_market() {
    // Only trigger the market when everybody has participated
    require(number_of_participation == number_of_participant);

    // Reset the market participation
    number_of_participation = 0;

    // Calculate the ratio between production and consumption
    uint ratio = total_consumption * 100 / total_production;

    // The network need more local production
    if (ratio >= upper_ratio) {
      // Local energy is at its maximum price
      selling_price = maximum_local_selling_price;

      // Buying price depends on the portion of local energy
      // Local energy price * ratio + retail price for the remaining energy
      buying_price = selling_price * 100 / ratio + retail_price - retail_price * 100 / ratio;
    }

    // The network is slowly approaching 100% local production
    // The price of buying local generation goes down to avoid back feeding
    if (ratio < upper_ratio && ratio >= lower_ratio) {
      // Linear equation joining the maximum selling price to the minimum selling price
      uint a = (maximum_local_selling_price - minimum_local_selling_price) / (upper_ratio - lower_ratio);
      uint b = minimum_local_selling_price - a * lower_ratio;
      selling_price = a * ratio + b;

      // Buying price depends on the portion of local energy and its price
      // Same equatio as previous section
      buying_price = selling_price * 100 / ratio + retail_price - retail_price * 100 / ratio;
    }

    // Local generatio is back feeding to the main grid
    if (ratio < lower_ratio) {
      // Buying and selling happen at the minimum price
      // Since retail price for generation is higher than minimum selling price
      // the market generate value for itself
      selling_price = minimum_local_selling_price;
      buying_price = minimum_local_buying_price;
    }

    // Reset total production and total consumption for this round
    total_consumption = 0;
    total_production = 0;

    // Send a bill to all the participants
    bill_all_participants();
  }

  function bill_all_participants() {
    // Loop over all the participants
    for (uint i = 0; i < participants.length; i++) {

      // Bill participant differently if they are prosumers or consumers
      if (energy_balance[participants[i]] > 0) {
        // Participant consumed power (energy_balance is positive)
        bill[participants[i]] += buying_price * energy_balance[participants[i]];
      } else {
        // Participant produced energy (energy_balance is negative)
        bill[participants[i]] += selling_price * energy_balance[participants[i]];
      }
    }
  }

  // End of the contract
}
