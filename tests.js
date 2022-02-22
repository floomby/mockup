const Web3 = require('web3');
const assert = require('assert');
const BN = require('bn.js');
// ganache
const web3 = new Web3('HTTP://127.0.0.1:7545');

const contracts = require('./compiled');

// Put your own ganache keys here
const adminAccount = web3.eth.accounts.wallet.add("c2b1b5be39103b894e6b2582669a3df6048236b517f22009e315c942286616fc");
const testAccount = web3.eth.accounts.wallet.add("175525cae816e2b48369f85a42487eb05490c61441c7b9041f7094f5cd30f666");

const deployContract = async (abi, bin, args) => {
    return new Promise((resolve, reject) => {
        const contract = new web3.eth.Contract(abi);
        contract.deploy({ data: bin, arguments: args }).estimateGas({ from: adminAccount.address }, (err, gas) => {
            if (err) return console.error(err);
            contract.deploy({ data: bin, arguments: args }).send({
                from: adminAccount.address,
                gas: gas,
                gasPrice: web3.utils.toWei('30', 'gwei')
            }, (error, transactionHash) => { /* console.dir(['sending', error, transactionHash]); */ })
            .on('error', error => { reject(error); })
            // .on('transactionHash', transactionHash => { console.dir(['txhash', transactionHash]); })
            // .on('receipt', receipt => { console.dir(['receipt', receipt.contractAddress]); })
            .on('confirmation', (confirmationNumber, receipt) => {
                if (confirmationNumber === 1) {
                    // console.dir(['confirmation', confirmationNumber, receipt]);
                    resolve(receipt.contractAddress);
                }
            })
            .then(newContractInstance => { /* console.dir(['new instance', newContractInstance.options.address]); */ });
        });
    });
};

const callMethod = (closure, account, amount) => {
    return new Promise((resolve, reject) => {
        closure.estimateGas({ from: account.address }, (err, gas) => {
            if (err) return reject(err);
            closure.send({
                from: account.address,
                gas: 200000,
                gasPrice: web3.utils.toWei('30', 'gwei'),
                value: amount === undefined ? '0' : amount
            }, (error, transactionHash) => { /* console.dir(['sending', error, transactionHash]); */ })
            .on('transactionHash', hash => { /* console.dir(['txhash', hash]); */ })
            .on('confirmation', (confirmationNumber, receipt) => {
                if (confirmationNumber === 1) {
                    // console.dir(['confirmation', confirmationNumber, receipt]);
                    resolve(receipt.gasUsed);
                }
            })
            .on('receipt', receipt => { /* console.dir(['receipt', receipt]); */ })
            .on('error', (error, receipt) => { reject(error); });
        });
    });
};

let aero = {}, airport = {}, route = {};

const deployContracts = async (cb) => {
    const aeroAddress = await deployContract(contracts.aero_abi, contracts.aero_bin, []);
    aero = { address: aeroAddress, contract: new web3.eth.Contract(contracts.aero_abi, aeroAddress) };
    console.log("deployed aero");

    const airportAddress = await deployContract(contracts.airport_abi, contracts.airport_bin, ['airportmetadatauri', aeroAddress]);
    airport = { address: airportAddress, contract: new web3.eth.Contract(contracts.airport_abi, airportAddress) };
    console.log("deployed airport");
    await callMethod(aero.contract.methods.setAirportAddress(airportAddress), adminAccount);
    
    const routeAddress = await deployContract(contracts.route_abi, contracts.route_bin, ['routemetadatauri', aeroAddress]);
    route = { address: routeAddress, contract: new web3.eth.Contract(contracts.route_abi, routeAddress) };
    console.log("deployed route");
    await callMethod(aero.contract.methods.setRouteAddress(routeAddress), adminAccount);

    console.dir([aero, airport, route].map(x => x.address));
    if(cb) cb();
};

const gasPrice = new BN(web3.utils.toWei('30', 'gwei'), 10);

// TODO figure out the best way to represent testing behaviors
const runTests = async () => {
    console.log("make sure minting airports");
    await callMethod(airport.contract.methods.mint(testAccount.address), adminAccount);
    let count = await airport.contract.methods.totalSupply().call();
    assert(count === '1');

    console.log("check purchasing aero");
    await callMethod(aero.contract.methods.purchase(), testAccount, '1000');
    count = await aero.contract.methods.balanceOf(testAccount.address).call();
    assert(count === '1000');

    console.log("check purchasing runways");
    await callMethod(airport.contract.methods.addRunway(0), testAccount);
    count = await aero.contract.methods.balanceOf(testAccount.address).call();
    assert(count === '900');

    console.log("check things burned properly when purchasing");
    count = await aero.contract.methods.totalSupply().call();
    assert(count === '900');

    console.log("check admin account balance");
    count = await web3.eth.getBalance(aero.address);
    assert(count === '1000');

    console.log("check withdrawals");
    let accountBalanceBefore = new BN(await web3.eth.getBalance(adminAccount.address), 10);
    let gasUsed = new BN(await callMethod(aero.contract.methods.withdraw(), adminAccount), 10);
    count = await web3.eth.getBalance(aero.address);
    assert(count === '0');
    let accountBalanceAfter = new BN(await web3.eth.getBalance(adminAccount.address), 10);
    let delta = gasPrice.mul(gasUsed).sub(accountBalanceBefore.sub(accountBalanceAfter));
    assert(delta.toString() === '1000');

    console.log("tests passed");
    process.exit(0);
};

deployContracts(runTests);