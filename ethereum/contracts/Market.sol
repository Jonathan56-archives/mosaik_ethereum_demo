pragma solidity ^0.4.4;


contract Market {
  // Participant addresses
  address[] public participants;

  // Last energy balance per participant [Wh]
  mapping (address => int) energy_balance;

  // Total production [Wh]
  uint total_production = 0;

  // Total consumption [Wh]
  uint total_consumption = 0;

  // Total number of participants
  uint public number_of_participant = 0;

  // Number of participation during a round
  uint number_of_participation = 0;

  // Retail price [$/Wh]
  uint retail_price = 100;

  // Retail price upper limit [%]
  uint upper_ratio = 166;

  // Retail price lower limit [%]
  uint lower_ratio = 50;

  // Buying price [$/Wh]
  uint buying_price = 0;

  // Selling price [$/Wh]
  uint selling_price = 0;

  // Maximum / minimum local selling price
  uint maximum_local_selling_price = (3 * retail_price) / 2;
  uint minimum_local_selling_price = retail_price / 2;

  // Minimum local buying price
  uint minimum_local_buying_price = retail_price / 2;

  // Bill per participant [$]
  mapping (address => int) bill;

  /* **********
      Event
  *********** */

  // NOT IMPLEMENTED YET
  event energy_posted_event(address _target, int _value);
  event market_cleared_event(uint _sell, uint _buy, uint ratio, uint _prod, uint _gen);
  event bill_sent_event(address _target, int _value);

  /* **********
    Function
  *********** */

  // Add a participant to the market
  function add_participant(){
    // Add the address of the participant to the "phone book"
    participants.push(msg.sender);

    // Increment the number of participants
    number_of_participant += 1;

    // Set participant bill to zero
    bill[msg.sender] = 0;

    // Set energy balance to zero
    energy_balance[msg.sender] = 0;
  }

  // Remove a participant from the market
  function remove_participant() {
    // NOT IMPLEMENTED YET
  }

  // Broadcast energy balance
  function post_energy_balance(int amount) {
    // Set participant last energy balance
    energy_balance[msg.sender] = amount;
    energy_posted_event(msg.sender, amount);

    // Increase total production or consumption
    if (amount > 0)
      // ratio need to be a positive number, so we ABS(amount)
      total_production += uint(-1 * amount);
    else
      total_consumption += uint(amount);

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

    // Event marked cleared
    market_cleared_event(selling_price, buying_price, ratio, total_consumption, total_production);

    // Reset total production and total consumption for this round
    total_consumption = 0;
    total_production = 0;

    // Send a bill to all the participants
    _bill_all_participants();
  }

  function _bill_all_participants() {
    // Loop over all the participants
    for (uint i = 0; i < participants.length; i++) {

      // Bill participant differently if they are prosumers or consumers
      if (energy_balance[participants[i]] > 0) {
        // Participant consumed power (energy_balance is positive)
        int positive_bill = int(buying_price) * energy_balance[participants[i]];
        bill[participants[i]] += positive_bill;
        bill_sent_event(participants[i], positive_bill);

      } else {
        // Participant produced energy (energy_balance is negative)
        int negative_bill = int(selling_price) * energy_balance[participants[i]];
        bill[participants[i]] += negative_bill;
        bill_sent_event(participants[i], negative_bill);
      }
    }
  }

  // End of the contract
}
