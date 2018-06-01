const BigNumber = web3.BigNumber;
const Wallet = require('ethereumjs-wallet');

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const StandardTokenMock = artifacts.require('StandardTokenMock');
const TokenSale_GasTokenFactory = artifacts.require('TokenSale_GasTokenFactory');
const BenchMark = artifacts.require('BenchMark');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

contract('TokenSale_GasTokenFactory', function ([_, owner, wallet, anyone]) {

  const totalSupply = 1000000000000000; // Token total supply
  const rate = 10;                      // How many token units a buyer gets per wei

  context('When TokenSale_GasTokenFactory & token contract are deployed', function (){
    beforeEach(async function () {
      this.token = await StandardTokenMock.new(owner, totalSupply, {from: owner});
      this.sale  = await TokenSale_GasTokenFactory.new(rate, wallet, this.token.address, {from : owner});
      this.bench = await BenchMark.new(this.sale.address, {from : owner});
    
      //Fund sale with tokens
      await this.token.transfer(this.sale.address, totalSupply, {from : owner});
    });

    describe('setUserCap() function', function () {

      const cap = 100;
      var tx; 

      beforeEach(async function () {
        tx = await this.sale.setUserCap(anyone, cap, {from: owner});
      });

      it('should increment totalGasTokenSupply() by 1', async function () {
        //Printing gas used for setUserCap
        console.log('setUserCap() gas used : ' + tx.receipt.gasUsed);
        
        // Retrieve gasToken total supply
        let totalSupplyGasToken = await this.sale.totalGasTokenSupply();

        totalSupplyGasToken.should.be.bignumber.equal(1);
      })

    })


    context('When 500 users are registered and contributed', function () {

      const nLoops = [11, 25, 43, 66, 111, 127, 155]; 
      const nBuyers = 500;  // Make sure this is enough to cover each tests 
      const cap     = 100; // Purchase cap
      var tx; 

      beforeEach(async function () {
        let wallet;
        let address;

        for (var i = 0; i < nBuyers; i++) {
          wallet = Wallet.generate();
          address = wallet.getAddressString();

          await this.sale.setUserCap(address, cap, {from: owner, gasPrice: 1});
          await this.sale.buyTokens(address, {from: owner, value: 1})
        }
      });

      context('When sale is finalize', function () {
        var cost1;

        beforeEach(async function () {
          await this.sale.finalizeSale({from: owner});
          cost1 = await this.sale.getFreeStorageCost(1);
        });

        it('should allow anyone to buy gasTokens', async function () {
          await this.sale.freeStorage(1, {from : anyone, value: cost1}).should.be.fulfilled;
        })

        it('getOptimalGasTokenAmount() should return the optimal amount', async function(){
          var nGasToken, costOptim, txBase, txPreOptim, txOptim, txPostOptim;
          var preOptimGasPerToken, optimGasPerToken, postOptimGasPerToken;
          var benchMarkGas;

          // Testing different function costs
          for (var i = 0; i < nLoops.length; i++) {

            txBase = await this.bench.benchMark(nLoops[i], 0);
            benchMarkGas = txBase.receipt.gasUsed;
            //console.log('\nBenchGas : ' + benchMarkGas)

            // Optimal number of gasTokens
            nGasToken = await this.sale.getOptimalGasTokenAmount(benchMarkGas);

            // Cost to pay for gasTokens
            costOptim = await this.sale.getFreeStorageCost(nGasToken);

            // Benchmarks with nGasTokens
            txPreOptim = await this.bench.benchMark(nLoops[i], nGasToken.minus(1), {value : costOptim.minus(cost1)});
            txOptim = await this.bench.benchMark(nLoops[i], nGasToken, {value: costOptim});
            txPostOptim = await this.bench.benchMark(nLoops[i], nGasToken.plus(1), {value: costOptim.plus(cost1)});

            // Calculating gas refunded per token consumed
            preOptimGasPerToken = (benchMarkGas - txPreOptim.receipt.gasUsed) / (nGasToken.c[0] - 1); 
            optimGasPerToken = (benchMarkGas - txOptim.receipt.gasUsed) / (nGasToken.c[0]); 
            postOptimGasPerToken = (benchMarkGas - txPostOptim.receipt.gasUsed) / (nGasToken.c[0] + 1);

            //console.log('preOptimal %d  : ' + preOptimGasPerToken, nGasToken.c[0] - 1 );
            //console.log('optimal %d     : ' + optimGasPerToken, nGasToken.c[0]);
            //console.log('postOptimal %d : ' + postOptimGasPerToken, nGasToken.c[0] + 1);

            // optimGasPerToken should be optimal
            (preOptimGasPerToken).should.be.lessThan(optimGasPerToken);
            (postOptimGasPerToken).should.be.lessThan(optimGasPerToken);

          }
        });
      })
    })
  })
})

async function benchMark(contract, nLoop, nGasTokens, cost1) {
  let tx0 = await contract.benchMark(nLoop, 0);
  let  tx = await contract.benchMark(nLoop, nGasTokens, {value: cost1.mul(nGasTokens)});

  if (nGasTokens != 0) {
    console.log('\nGas used with %d gasToken consumed : ' + tx.receipt.gasUsed, nGasTokens);
    console.log('Gas saved per token : ' +  (tx0.receipt.gasUsed - tx.receipt.gasUsed) / nGasTokens);
  } else {
    console.log('\nGas used with 0 gasToken consumed : ' + tx.receipt.gasUsed);
  }
  return tx.receipt.gasUsed;
}