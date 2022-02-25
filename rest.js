// Just need test stuff for the oracle (I want a prng anyways)

import express from 'express';
import MersenneTwister from 'mersenne-twister';
const app = express();
const port = 3000;
const generator = new MersenneTwister();

app.get('/prng', (req, res) => {
    res.send(JSON.stringify(generator.random_int()));
})

app.listen(port, () => {
    console.log(`Listening on port ${port}`);
})