var Bounty0xPreSale = artifacts.require("./Bounty0xPreSale.sol");

contract('Bounty0xPreSale', function(accounts) {
    it("owner should be account[0],", function() {
        var account_one = accounts[0];
        return Bounty0xPreSale.deployed().then(function(contract) {
            return contract.owner.call().then(function(ownerReturned) {
                assert.equal(ownerReturned, account_one);
            });
        });
    });

        it("intial max cap should be 3.78,", function() {
        var account_one = accounts[0];
        return Bounty0xPreSale.deployed().then(function(contract) {
            return contract.MAXIMUM_PARTICIPATION_AMOUNT.call().then(function(maxParticipation) {
                assert.equal(web3.fromWei(maxParticipation.valueOf()), 3.78);
            });
        });
    });

    it("Max cap should be 30000, post whitelist turn off,", function() {
        return Bounty0xPreSale.deployed().then(function(contract) {
            return contract.whitelistFilteringSwitch({from: '0xc242b49788caa7068800bc9b43588afeb797b11a'}).then(function() {
                return contract.MAXIMUM_PARTICIPATION_AMOUNT.call().then(function (valueReturned) {
                    assert.equal(web3.fromWei(valueReturned.valueOf()), 30000);
                });
            });
        });
    });
});