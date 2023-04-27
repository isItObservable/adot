const express = require('express')
const bodyParser = require('body-parser')
require('dotenv').config()
const path = require("path");
const tracer = require('./instrumentation')
const server = express()
const router = express.Router();
const { upload } = require('/multer-s3-fileupload/s3UploadClient')

// Ensure that S3 Bucket is properly loaded
console.log('S3 BUCKET', process.env.AWS_S3_BUCKET)

// Middleware Plugins

// Routes

router.get('/',function(req,res){
  res.sendFile(path.join(__dirname+'/public/upload.html'));
  //__dirname : It will resolve to your project folder.
});

router.post('/upload', upload.array('inputFile', 3), (req, res) => {
       if (!req.files) res.status(400).json({ error: 'No files were uploaded.' })

       res.status(201).json({
         message: 'Successfully uploaded ' + req.files.length + ' files!',
         files: req.files
       })
});

server.use(bodyParser.json())
server.use("/", router);
const port=process.env.PORT
// Start the server
server.listen(port, error => {
  if (error) console.error('Error starting', error)
  else console.log('Started at http://localhost:'+port)
})