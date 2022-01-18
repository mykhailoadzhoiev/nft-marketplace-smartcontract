const Matcher = artifacts.require('AtomicMatcher')
const Factory = artifacts.require('NFTContract')
const TasteToken = artifacts.require('CoinToken')

const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers')

const feeTakerAddress1 = "0xFbc147659f5297983D2fBdf6C6aE45Ae9ceCF2E9"
const feeTakerAddress2 = "0x2e11d23151e595211e63D2724764477B0F4Fad1E"
const feeTakerAddress3 = "0x9987605c8741d945098D7D6ba30bC41ACc1B821e"

contract('Matcher', (accounts) => {
  let matcher, factory, token

  before(async () => {
    factory = await Factory.new("TEST", "TEST", accounts[0])
    token = await TasteToken.new("TASTE", "TASTE", 9, 1000000000000, 5, 5, 100000000000000, 100000000000, accounts[4], accounts[3], {from: accounts[3]})
    await token.transfer(accounts[2], 100000, {from: accounts[3]})
    matcher = await Matcher.new(token.address, accounts[0])
  })

  // it('Test distribution', async () => {

  //   const creatorReward = new BN(15)
  //   const creator = accounts[0]
  //   const tokenPrice = new BN(100000)
  //   const order = {
  //     creator: creator,
  //     creatorReward: creatorReward.toString(),
  //     maker: accounts[1],
  //     taker: accounts[2],
  //     isFixedPrice: true,
  //     price: tokenPrice.toString(),
  //     extra: new BN(0),
  //     itemId: new BN(0),
  //     itemContract: factory.address
  //   }

  //   const res = await matcher.calculateFundsDistribution(order)
  //   const { _creator, _maker, _fee1, _fee2, _fee3 } = res
  //   const arr = [_creator, _maker, _fee1, _fee2, _fee3]
  //   const numbers = arr.map((e) => e.toNumber())
  //   console.log(numbers)
  //   const sum = numbers.reduce((a, v) => a + v)
  //   console.log('SUM: ', sum)
  //   console.log('APPROVED: ', tokenPrice.toString())

  // })

  it('Basic fix sell', async () => {
    const fee1Balance = await token.balanceOf(feeTakerAddress1)
    const fee2Balance = await token.balanceOf(feeTakerAddress2)
    const fee3Balance = await token.balanceOf(feeTakerAddress3)
    const creatorReward = new BN(15)
    const creator = accounts[0]


    // mint nft
    await factory.mint(1, accounts[1])

    // approve nft
    await factory.approve(matcher.address, 0, {from: accounts[1]})
    
    // approve amount
    const tokenPrice = new BN(100000)
    await token.approve(matcher.address, tokenPrice, {from: accounts[2]})

    // Prepare order
    const order = {
      creator: creator,
      creatorReward: creatorReward.toString(),
      maker: accounts[1],
      taker: accounts[2],
      isFixedPrice: true,
      price: tokenPrice.toString(),
      extra: new BN(0),
      itemId: new BN(0),
      itemContract: factory.address
    }

    const makerBalance = await token.balanceOf(order.maker)
    const takerBalance = await token.balanceOf(order.taker)

    // prepare signatures
    const sellerData = web3.utils.soliditySha3(
      order.maker, order.isFixedPrice, tokenPrice, new BN(order.itemId), order.itemContract
    )
    let sellerSignature = await web3.eth.sign(sellerData, accounts[1])
    sellerSignature = sellerSignature.substr(0, 130) + (sellerSignature.substr(130) == "00" ? "1b" : "1c");

    const buyerData = web3.utils.soliditySha3(
      order.taker, order.isFixedPrice, tokenPrice, new BN(order.extra), new BN(order.itemId), order.itemContract
    )
    let buyerSignature = await web3.eth.sign(buyerData, accounts[2])
    buyerSignature = buyerSignature.substr(0, 130) + (buyerSignature.substr(130) == "00" ? "1b" : "1c");

    // match order
    await matcher.atomicMatch(order, buyerSignature, sellerSignature)

    // check order
    const newfee1Balance = await token.balanceOf(feeTakerAddress1)
    const newfee2Balance = await token.balanceOf(feeTakerAddress2)
    const newfee3Balance = await token.balanceOf(feeTakerAddress3)
    const newMakerBalance = await token.balanceOf(order.maker)
    const newTakerBalance = await token.balanceOf(order.taker)

    expect(newfee1Balance.toNumber()).to.be.equal(fee1Balance.toNumber() + tokenPrice * 0.03 - tokenPrice * 0.03 * 0.1)
    expect(newfee2Balance.toNumber()).to.be.equal(fee2Balance.toNumber() + tokenPrice * 0.03 - tokenPrice * 0.03 * 0.1)
    expect(newfee3Balance.toNumber()).to.be.equal(fee3Balance.toNumber() + tokenPrice * 0.04 - tokenPrice * 0.04 * 0.1)
    expect(newMakerBalance.toNumber()).to.be.equal(makerBalance.toNumber() + tokenPrice * 0.75 - tokenPrice * 0.75 * 0.1)
    expect(newTakerBalance.toNumber()).to.be.equal(takerBalance.toNumber() - tokenPrice)
  })
})