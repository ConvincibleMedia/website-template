const SiteClient = require('datocms-client').SiteClient;
const fs = require('fs');
const path = require('path');
const request = require('request');

// READ ENVIRONMENT VARIABLE
const API_KEY = 'DATO_API_TOKEN=';
var API_TOKEN = '';
if (fs.existsSync('.env')) {
   console.log('Found local .env file');
   var data = fs.readFileSync('.env', 'utf8');
   if (data.includes(API_KEY)) {
      API_TOKEN = data.substr((data.lastIndexOf(API_KEY) + API_KEY.length) - data.length).trim();
   }
}
if (API_TOKEN.length == 0) {
   API_TOKEN = process.env.DATO_API_TOKEN;
}
console.log('API Token = "' + API_TOKEN + '"');

// CONNECT
var client = new SiteClient(API_TOKEN);

console.log('Downloading data...');

client.items.all({}, {
      allPages: true
   })
   .then(response => {
      fs.writeFileSync('./backup/records.json', JSON.stringify(response, null, 2));
      console.log('Wrote records.json');
   })
   .then(() => {
      return client.site.find();
   })
   .then((site) => {
      client.uploads.all({}, {
            allPages: true
         })
         .then(uploads => {
            return uploads.reduce((chain, upload) => {
               return chain.then(() => {
                  return new Promise((resolve) => {
                     const imageUrl = 'https://' + site.imgixHost + upload.path;
                     console.log(`Downloading ${imageUrl}...`);
                     const stream = fs.createWriteStream('./backup/assets/img' + path.basename(upload.path));
                     stream.on('close', resolve);
                     request(imageUrl).pipe(stream);
                  });
               });
            }, Promise.resolve());
         });
   });
