let express    = require("express");
let path = require("path");
let bodyParser = require("body-parser");
let morgan = require("morgan");

let index = require("./routes/index");
let users = require("./routes/users");
let api = require("./routes/api");

let app = express();

app.set("views",path.join(__dirname, 'views'));
app.set("view engine", "pug");

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: false}));
app.use("/public",express.static(path.join(__dirname, 'public')));
app.use(morgan("dev"));

app.use("/", index);

let Pi = require("./bin/RaspberryFct");
Pi.encodeBootstrap();

app.use(function(req,res,next){
    let err = new Error('Not Found');
    err.status = 404;
    next(err);
});

app.use(function(err,req,res,next){
    res.locals.message = err.message;
    res.locals.error = req.app.get('env') === 'development' ? err : {};

    res.status(err.status||500);
    res.render('error');
});

module.exports = app;