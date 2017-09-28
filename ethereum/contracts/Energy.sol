pragma solidity ^0.4.4;

contract Energy {

  // Token for the amount of kWh produced
  mapping (address => uint) genetoken;

  // Token for the amount of kWh consumed
  mapping (address => uint) constoken;

  // Money balance
  mapping (address => uint) balance;

  // Event added consumption
  event addedConsumption(address _target, uint _value);

  // Event added generation
  event addedGeneration(address _target, uint _value);

  // net meter update generation tokens
  function addGenerationToken(address receiver, uint amount) {
    genetoken[receiver] += amount;
    addedGeneration(receiver, amount);
  }

  // get generation tokens
  function generationTokenBalance(address account) constant returns(uint) {
    return genetoken[account];
  }

  // net meter update consumption tokens
  function addConsumptionToken(address receiver, uint amount) {
    constoken[receiver] += amount;
    addedConsumption(receiver, amount);
  }

  // get consumption tokens
  function consumptionTokenBalance(address account) constant returns(uint) {
    return constoken[account];
  }

  // TODO: create a way to balance out gen and cons tokens through money exchange
}
