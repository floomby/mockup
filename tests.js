const Web3 = require('web3');
// ganache
const web3 = new Web3('HTTP://127.0.0.1:7545');

const contracts = require('./compiled');

const adminAccount = web3.eth.accounts.wallet.add("c2b1b5be39103b894e6b2582669a3df6048236b517f22009e315c942286616fc");
const testAccount = web3.eth.accounts.wallet.add("175525cae816e2b48369f85a42487eb05490c61441c7b9041f7094f5cd30f666");

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

const callMethod = (closure, account, cb) => {
    return new Promise((resolve, reject) => {
        closure.estimateGas({ from: account.address }, (err, gas) => {
            if (err) return reject(err);
            closure.send({
                from: account.address,
                gas: 200000,
                gasPrice: web3.utils.toWei('30', 'gwei')
            }, (error, transactionHash) => { /* console.dir(['sending', error, transactionHash]); */ })
            .on('transactionHash', hash => { /* console.dir(['txhash', hash]); */ })
            .on('confirmation', (confirmationNumber, receipt) => {
                if (confirmationNumber === 1) {
                    // console.dir(['confirmation', confirmationNumber, receipt]);
                    resolve();
                }
            })
            .on('receipt', receipt => { /* console.dir(['receipt', receipt]); */ })
            .on('error', (error, receipt) => { reject(error); });
        });
    });
};

let aero = {}, airport = {}, route = {};

const deployContracts = (cb) => {
    deployContract(contracts.aero_abi, contracts.aero_bin, [5000], (address, contract) => {
        aero = { address, contract: new web3.eth.Contract(contracts.aero_abi, address) };
        console.log("deployed aero");
        deployContract(contracts.airport_abi, contracts.airport_bin, ['airportmetadatauri', address], async (address, contract) => {
            console.log("deployed airport");
            airport = { address, contract: new web3.eth.Contract(contracts.airport_abi, address) };
            await callMethod(aero.contract.methods.setRouteAddress(address), adminAccount);
            deployContract(contracts.route_abi, contracts.route_bin, ['routemetadatauri', aero.address], async (address, contract) => {
                route = { address, contract: new web3.eth.Contract(contracts.route_abi, address) };
                console.log("deployed route");
                await callMethod(aero.contract.methods.setRouteAddress(address), adminAccount);
                console.dir([aero, airport, route].map(x => x.address));
                if(cb) cb();
            });
        });
    });
};

// TODO figure out the best way to represent testing behaviors
const runTests = () => {
    // Mint an airport for the test account
};


deployContracts(runTests);