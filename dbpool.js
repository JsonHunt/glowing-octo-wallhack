// Generated by CoffeeScript 1.9.1
(function() {
  var mysql, pool;

  mysql = require('mysql');

  pool = mysql.createPool({
    connectionLimit: 10,
    host: 'localhost',
    user: 'root',
    password: 'garsonka',
    database: 'callfanout'
  });

  exports.pool = pool;

}).call(this);
