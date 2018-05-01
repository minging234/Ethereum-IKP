// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract';

// Import our contract artifacts and turn them into usable abstractions.
import greeter_artifacts from '../../build/contracts/Greeter.json';
import ikp_artifacts from '../../build/contracts/RIKP.json';
import dcp_artifacts from '../../build/contracts/CheckContract.json';
import rp_artifacts from '../../build/contracts/reaction.json';
// Greeter is our usable abstraction, which we'll use through the code below.
 var Greeter = contract(greeter_artifacts);

var IKP = contract(ikp_artifacts);
var DCP = contract(dcp_artifacts);
var RP = contract(rp_artifacts);


// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;

window.App = {
  start: function() {
    var self = this;
    // document.getElementById("greet").style.visibility='hidden';
    // document.getElementById("greet").style.visibility='visible';

    document.getElementById("CA").style.display='none';
    document.getElementById("client").style.display='none';
    document.getElementById("greet").style.display='none';
    document.getElementById("Domain").style.display='none';


    // Bootstrap the MetaCoin abstraction for Use.
    Greeter.setProvider(web3.currentProvider);

    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function(err, accs) {
      if (err != null) {
        alert("There was an error fetching your accounts.");
        return;
      }

      if (accs.length == 0) {
        alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
        return;
      }

      accounts = accs;
      account = accounts[0];

      // self.refreshBalance();
      self.showGreet();
      
    });
  },

  chooseCA: function() {
    document.getElementById("CA").style.display='inherit';
    document.getElementById("client").style.display='none';
    document.getElementById("Domain").style.display='none';
  },

  chooseDomain: function() {
    document.getElementById("CA").style.display='none';
    document.getElementById("client").style.display='none';
    document.getElementById("Domain").style.display='inherit';
  },

  chooseClient: function() {
    document.getElementById("client").style.display='inherit';
    document.getElementById("CA").style.display='none';
    document.getElementById("Domain").style.display='none';
  },

  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },

  // refreshBalance: function() {
  //   var self = this;

  //   var meta;
    // MetaCoin.deployed().then(function(instance) {
    //   meta = instance;
    //   return meta.getBalance.call(account, {from: account});
    // }).then(function(value) {
    //   var balance_element = document.getElementById("balance");
    //   balance_element.innerHTML = value.valueOf();
    // }).catch(function(e) {
    //   console.log(e);
    //   self.setStatus("Error getting balance; see log.");
    // });
  // },
  showGreet: function() {
    var self = this;
    var gre;
    Greeter.deployed().then(function(instance) {
      gre = instance;
      return gre.greet.call(account,{from:account});
    }).then(function(value){
      var greetWord = document.getElementById("balance");
      greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  Domainregister: function() {
    var self = this;
    var ikp;
    var dcp
    var domainname = document.getElementById("domainname").value;
    var checkeraddress = document.getElementById("checkeraddress").value;
    var Domainthreshold = document.getElementById("Domainthreshold").value;


    IKP.deployed().then(function (instance) {
      ikp = instance;
      return DCP.deployed()
    }).then(function(instance) {
      dcp = instance;
      ikp.domainRegister.call("www.google.com", dcp.address, Domainthreshold, {from: account, value: web3.toWei(1, "ether")});
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  RPPurchase: function() {
    var self = this;
    var ikp;
    var RPHash = document.getElementById("RPHash").value;
    var RPissuer = document.getElementById("RPissuer").value;



    IKP.deployed().then(function(instance) {
      ikp = instance;
      return ikp.rpPurchase.call(RPHash,RPissuer,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  caregister: function() {
    var self = this;
    var ikp;
    var caname = document.getElementById("caname").value;
    var publickey = document.getElementById("publickey").value;
    var threshold = document.getElementById("threshold").value;


    IKP.deployed().then(function(instance) {
      ikp = instance;
      return ikp.caRegister.call(caname,publickey,threshold,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  issue_RP: function() {
    var self = this;
    var ikp;
    var issueRP = document.getElementById("issueRP").value;

    IKP.deployed().then(function(instance) {
      ikp = instance;
      return ikp.rpIssue.call(issueRP,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  revokecert: function() {
    var self = this;
    var ikp;
    var revokecert = document.getElementById("revokecert").value;

    IKP.deployed().then(function(instance) {
      ikp = instance;
      return ikp.revoke.call(revokecert,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  check: function() {
    var self = this;
    var ikp;
    var certToVerify = document.getElementById("certToVerify").value;

    IKP.deployed().then(function(instance) {
      ikp = instance;
      // need to be editted
      return ikp.isRevoked.call(certToVerify,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  getRevoke: function() {
    var self = this;
    var ikp;
    var certisrevoke = document.getElementById("certisrevoke").value;

    IKP.deployed().then(function(instance) {
      ikp = instance;
      return ikp.isRevoked.call(certisrevoke,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  sendcommit: function() {
    var self = this;
    var ikp;
    var cert = document.getElementById("cert").value;
    var nonce = document.getElementById("nonce").value;

    IKP.deployed().then(function(instance) {
      ikp = instance;
      return ikp.reportCommit.call(cert,nonce,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },

  reveal: function() {
    var self = this;
    var ikp;
    var cert = document.getElementById("cert").value;
    var nonce = document.getElementById("nonce").value;

    IKP.deployed().then(function(instance) {
      ikp = instance;
      return ikp.reportReveal.call(cert,nonce,{from:account});
    }).then(function(value){
      // var greetWord = document.getElementById("balance");
      // greetWord.innerHTML = value.valueOf();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting greet word; see log.");
    });
  },
  // sendCoin: function() {
  //   var self = this;

  //   var amount = parseInt(document.getElementById("amount").value);
  //   var receiver = document.getElementById("receiver").value;

  //   this.setStatus("Initiating transaction... (please wait)");

  //   var meta;
  //   MetaCoin.deployed().then(function(instance) {
  //     meta = instance;
  //     return meta.sendCoin(receiver, amount, {from: account});
  //   }).then(function() {
  //     self.setStatus("Transaction complete!");
  //     self.refreshBalance();
  //   }).catch(function(e) {
  //     console.log(e);
  //     self.setStatus("Error sending coin; see log.");
  //   });
  // }

    setGreet: function() {
      var self = this;
      var greetWord = document.getElementById("receiver").value;
      this.setStatus("setting greet word.....(please wait)");
      var gre;
      Greeter.deployed().then(function(instance) {
        gre = instance;
        return gre.setGreeting(greetWord,{from:account});
      }).then(function() {
        self.setStatus("Setting complete!");
        self.showGreet();
      }).catch(function(e) {
        console.log(e);
        self.setStatus("Error setting greet word; see log")
      });
    }

};

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:7545"));
  }

  App.start();
});
