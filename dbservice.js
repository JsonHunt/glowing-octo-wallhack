// Generated by CoffeeScript 1.9.1
(function() {
  var bunyan, getLastFanout, getLastMessage, mysql, pool;

  mysql = require('mysql');

  pool = require('./dbpool').pool;

  bunyan = require('bunyan');

  module.exports.deleteEverything = function(callback) {
    return pool.query("TRUNCATE TABLE message", function() {
      return pool.query("TRUNCATE TABLE fanout", function() {
        return pool.query("TRUNCATE TABLE phonecall", function() {
          return pool.query("TRUNCATE TABLE person", callback);
        });
      });
    });
  };

  module.exports.newFanout = function(callback) {
    return getLastMessage(function(err, msg) {
      var sql;
      sql = mysql.format("INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [new Date(), msg.id]);
      return pool.query(sql, callback);
    });
  };

  module.exports.getAllFanouts = function(callback) {
    return pool.query("SELECT * FROM fanout", function(err, rows, fields) {
      return callback(void 0, rows);
    });
  };

  module.exports.getLastFanout = getLastFanout = function(callback) {
    return pool.query("SELECT * FROM fanout ORDER BY dateStarted DESC LIMIT 1", function(err, rows, fields) {
      var row;
      row = rows.length > 0 ? rows[0] : void 0;
      return callback(void 0, row);
    });
  };

  module.exports.savePerson = function(person, callback) {
    return callback();
  };

  module.exports.getAllPeople = function(callback) {
    return pool.query("SELECT * FROM person", callback);
  };

  module.exports.getPerson = function(id, callback) {
    return callback();
  };

  module.exports.findPersonByNumber = function(number, callback) {
    var sql;
    return sql = mysql.format("SELECT * FROM person WHERE number = ?", [number], function(err, rows, fields) {
      if (rows.length > 0) {
        return callback(err, people[0]);
      } else {
        return callback(err, void 0);
      }
    });
  };

  module.exports.newMessage = function(url, callback) {
    var sql;
    sql = mysql.format("INSERT INTO message (dateCreated,url) VALUES (?,?)", [new Date(), url]);
    return pool.query(sql, callback);
  };

  module.exports.registerCall = function(fanoutID, number, status, confirmed, callback) {
    var sql;
    sql = mysql.format("INSERT INTO phonecall (dateConnected, fanout_id, number, status, confirmed) VALUES (?,?,?,?,?)", [new Date(), fanoutID, number, status, confirmed]);
    return pool.query(sql, callback);
  };

  module.exports.getLastMessage = getLastMessage = function(callback) {
    return pool.query("SELECT * FROM message ORDER BY `dateCreated` DESC LIMIT 1", function(err, rows, fields) {
      var msg;
      msg = rows.length > 0 ? rows[0] : void 0;
      return callback(void 0, msg);
    });
  };

  module.exports.getFanoutSummary = function(fanoutID, callback) {
    var summary;
    summary = {};
    return pool.query(mysql.format("SELECT * FROM fanout WHERE id = ?", [fanoutID]), function(err, results) {
      var inserts, sql;
      summary.fanout = results[0];
      sql = "SELECT * FROM phonecall c JOIN fanout f ON c.fanout_id = f.id JOIN person p ON p.number = c.number WHERE f.id = ?";
      inserts = [fanoutID];
      sql = mysql.format(sql, inserts);
      return pool.query(sql, function(err, results) {
        if (err) {
          console.log(err);
        }
        summary.calls = results;
        return callback(void 0, summary);
      });
    });
  };

  module.exports.verifyAdminPassword = function(pass, callback) {
    return callback(void 0, true);
  };

}).call(this);
