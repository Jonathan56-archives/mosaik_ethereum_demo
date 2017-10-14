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
  uint upper_margin_coef = 150;

  // Retail price lower limit [%]
  uint lower_margin_coef = 50;

  // Buying price [$/kWh]
  uint buying_price = retail_price;

  // Selling price [$/kWh]
  uint selling_price = retail_price;

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
      total_production += amount;
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
    /*uint ratio = total_consumption * 100 / total_production;*/

    // Set a selling price

    // Set a buying price

    // Reset total production and total consumption for this round

    // Send a bill to all the participants

  }

  function bill_all_participants() {
    // Loop over all the participants

    // Add to the previous amount to be paid (price * energy_balance)
  }

}
