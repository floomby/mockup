import Web3 from 'web3';
import assert from 'assert';
import got from 'got';
import BN from 'bn.js';
import contracts from './compiled.js';

const web3 = new Web3('ws://127.0.0.1:7545');

// ganache keys
const adminAccount = web3.eth.accounts.wallet.add("c2b1b5be39103b894e6b2582669a3df6048236b517f22009e315c942286616fc");
const oracleAccount = web3.eth.accounts.wallet.add("175525cae816e2b48369f85a42487eb05490c61441c7b9041f7094f5cd30f666");
const testAccount = web3.eth.accounts.wallet.add("9cbc1edc8d77d4300d6c30bda07a01a3dd3b91af5366ca6b8469d0180f9186d2");


const deployContract = async (abi, bin, args, account) => {
    return new Promise((resolve, reject) => {
        let acc = account === undefined ? adminAccount : account;
        const contract = new web3.eth.Contract(abi);
        contract.deploy({ data: bin, arguments: args }).estimateGas({ from: acc.address }, (err, gas) => {
            if (err) return console.error(err);
            contract.deploy({ data: bin, arguments: args }).send({
                from: acc.address,
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

const callMethod = (closure, account, amount, nonce) => {
    return new Promise(async (resolve, reject) => {
        let non = nonce;
        if (non === undefined) non = await web3.eth.getTransactionCount(account.address, "pending");
        const value = amount === undefined ? '0' : amount;
        closure.estimateGas({ from: account.address, nonce: non, value }, async (err, gas) => {
            if (err) return reject(err);
            console.dir(gas);
            closure.send({
                from: account.address,
                gas: gas,
                gasPrice: web3.utils.toWei('30', 'gwei'),
                value, // I might need this is the estimation as well
                nonce: non
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

let aero = {}, airport = {}, route = {}, oracle = {};

const options = {
    filter: { value: [] },
    fromBlock: 0
};

let addedRoutes = [];

const addRoutes = (event) => {
    addedRoutes.push(event);
};

const addEventPrinter = (eventObject, cb) => {
    eventObject(options)
        .on('data', event => {
            console.log(event);
            if (cb) cb(event);
        })
        .on('error', err => { throw err; })
        // .on('changed', changed => console.log(changed))
        // .on('connected', str => console.log(str));
};

let oracleNonce;

// !!!! This does not handle stuck transactions and stuff (I will come up with a good way to handle it)
// The concurency of transactions is messing up
const oracleHandler = () => {
    oracle.contract.events.getValue(options)
        .on('data', async event => {
            console.dir(['data', event]);
            try {
                const contract = new web3.eth.Contract(contracts.ioraclable_abi, event.returnValues.from);
                const res = await got(event.returnValues.what).json();
                console.log(`Using nonce of ${oracleNonce}`);
                await callMethod(contract.methods.__callback(res.toString(), event.returnValues.id), oracleAccount, undefined, oracleNonce++);
            } catch (err) {
                console.dir(err);
            }
        })
        .on('error', err => { /* we might need to do something like this: nonce--; */ throw err; })
        // .on('changed', changed => console.dir(['changed', changed]))
        // .on('connected', str => console.dir(['connected', str]))
};

const deployContracts = async (cb) => {
    const aeroAddress = await deployContract(contracts.aero_abi, contracts.aero_bin, []);
    aero = { address: aeroAddress, contract: new web3.eth.Contract(contracts.aero_abi, aeroAddress) };
    console.log("deployed aero");

    const oracleAddress = await deployContract(contracts.oracle_abi, contracts.oracle_bin, [], oracleAccount);
    oracle = { address: oracleAddress, contract: new web3.eth.Contract(contracts.oracle_abi, oracleAddress) };
    console.log("deployed oracle");

    const airportAddress = await deployContract(contracts.airport_abi, contracts.airport_bin, ['airportmetadatauri?id=', aeroAddress]);
    airport = { address: airportAddress, contract: new web3.eth.Contract(contracts.airport_abi, airportAddress) };
    console.log("deployed airport");
    await callMethod(aero.contract.methods.setAirportAddress(airportAddress), adminAccount);
    
    const routeAddress = await deployContract(contracts.route_abi, contracts.route_bin,
        ['routemetadatauri', aeroAddress, oracleAddress, oracleAccount.address]);
    route = { address: routeAddress, contract: new web3.eth.Contract(contracts.route_abi, routeAddress) };
    console.log("deployed route");
    await callMethod(aero.contract.methods.setRouteAddress(routeAddress), adminAccount);
    
    oracleNonce = await web3.eth.getTransactionCount(oracleAccount.address, "pending");
    oracleHandler();

    addEventPrinter(route.contract.events.log);
    addEventPrinter(route.contract.events.routeAdded, addRoutes);

    console.dir([aero, airport, route, oracle].map(x => x.address));
    if(cb) cb();
};

const gasPrice = new BN(web3.utils.toWei('30', 'gwei'), 10);

const start = Date.now();

// TODO figure out the best way to represent testing behaviors (also important to test that error behavior maintains correct contract states)
const runTests = async () => {
    console.log("check airport minting");
    await callMethod(airport.contract.methods.mint(testAccount.address), adminAccount);
    let count = await airport.contract.methods.totalSupply().call();
    assert(count === '1');
    let uri = await airport.contract.methods.tokenURI(0).call();
    assert(uri === 'airportmetadatauri?id=0');

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

    console.log("check route acquisition");
    await callMethod(route.contract.methods.buyRoute(), testAccount);
    // TODO fix this waiting, it is not ideal
    await new Promise(r => setTimeout(r, 10000));
    assert(addedRoutes.length === 1);
    uri = await route.contract.methods.tokenURI(0).call();
    assert(uri === 'routemetadatauri?length=42&routeType=1&aircraftType=0');

    console.log("tests passed");
    console.log(`Took ${(Date.now() - start) / 1000} seconds`);
    process.exit(0);
};

deployContracts(runTests);