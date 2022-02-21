const Web3 = require('web3');
// ganache
const web3 = new Web3('HTTP://127.0.0.1:7545');

const contracts = require('./compiled');

const adminAccount = web3.eth.accounts.wallet.add("df796209562d1b017f1d9641517c88d003b4c5abd78bff305854a3f7610dcfb9");

const deployContract = async (abi, bin, args, cb) => {
    const contract = new web3.eth.Contract(abi);
    contract.deploy({ data: bin, arguments: args }).estimateGas({ from: adminAccount.address }, (err, gas) => {
        if (err) return console.error(err);
        contract.deploy({ data: bin, arguments: args }).send({
            from: adminAccount.address,
            gas: gas,
            gasPrice: web3.utils.toWei('30', 'gwei')
        }, (error, transactionHash) => { /* console.dir(['sending', error, transactionHash]); */ })
        .on('error', error => { console.dir(['error', error]); })
        // .on('transactionHash', transactionHash => { console.dir(['txhash', transactionHash]); })
        // .on('receipt', receipt => { console.dir(['receipt', receipt.contractAddress]); })
        .on('confirmation', (confirmationNumber, receipt) => {
            if (confirmationNumber === 1) {
                // console.dir(['confirmation', confirmationNumber, receipt]);
                cb(receipt.contractAddress, contract);
            }
        })
        .then(newContractInstance => { /* console.dir(['new instance', newContractInstance.options.address]); */ });
    });
};

const callMethod = (closure, contract, account, cb) => {
    closure.estimateGas({ from: account.address }, (err, gas) => {
        if (err) return console.error(err);
        closure.send({
            from: account.address,
            gas: 200000,
            gasPrice: web3.utils.toWei('30', 'gwei')
        }, (error, transactionHash) => { /* console.dir(['sending', error, transactionHash]); */ })
        .on('transactionHash', hash => { /* console.dir(['txhash', hash]); */ })
        .on('confirmation', (confirmationNumber, receipt) => {
            if (confirmationNumber === 1) {
                // console.dir(['confirmation', confirmationNumber, receipt]);
                cb(contract, account);
            }
        })
        .on('receipt', receipt => { /* console.dir(['receipt', receipt]); */ })
        .on('error', (error, receipt) => { console.dir(['error', error, receipt]); });
    });
};

let aero = {}, airport = {}, route = {};

const deployContracts = (cb) => {
    deployContract(contracts.aero_abi, contracts.aero_bin, [5000], (address, contract) => {
        aero = { address, contract: new web3.eth.Contract(contracts.aero_abi, address) };
        console.log("deployed aero");
        deployContract(contracts.airport_abi, contracts.airport_bin, ['airportmetadatauri', address], (address, contract) => {
            console.log("deployed airport");
            airport = { address, contract: new web3.eth.Contract(contracts.airport_abi, address) };
            callMethod(aero.contract.methods.setRouteAddress(address), aero.contract, adminAccount, (contract, account) => {
                deployContract(contracts.route_abi, contracts.route_bin, ['routemetadatauri', aero.address], (address, contract) => {
                    route = { address, contract: new web3.eth.Contract(contracts.route_abi, address) };
                    console.log("deployed route");
                    callMethod(aero.contract.methods.setRouteAddress(address), aero.contract, adminAccount, (contract, account) => {
                        console.dir([aero, airport, route].map(x => x.address));
                        if(cb) cb();
                    });
                });
            });
        });
    });
};

const runTests = () => {
    // TODO figure out the best way to represent testing behaviors
};


deployContracts(runTests);