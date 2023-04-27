import { Httpx } from 'https://jslib.k6.io/httpx/0.0.3/index.js';
import http from 'k6/http';
import { findBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';
import { sleep,check} from 'k6';
import { Counter } from "k6/metrics";
//import tracing, { Http } from 'k6/x/tracing';
/**
 * Hipster workload generator by k6
 * @param __ENV.FRONTEND_ADDR
 * @constructor yuxiaoba
 */

let errors = new Counter("errors");

const waittime = [5,6,7,8,9,10,11,12,14,15]

const url=`${__ENV.SERVICE_ADDR}`;


export function setup() {
//  console.log(`Running xk6-distributed-tracing v${tracing.version}`);
}
export const options = {
    discardResponseBodies: true,
    vus: 10,
    duration: '40m',
};

const session = new Httpx({
  baseURL: 'http://'+url,

  timeout: 20000, // 20s timeout.
});
const binFile = open('/load/batman-lego.jpg', 'b');
function makeid(length) {
    let result = '';
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    let counter = 0;
    while (counter < length) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength));
      counter += 1;
    }
    return result;
}

export default function() {
   //  const http = new Http({
     //   exporter: "otlp",
       // propagator: "w3c",
         //endpoint: url
      //});
    //Access index page

    let hom_res=session.get('/');
    let checkRes = check(hom_res, { "status is 200": (r) => r.status === 200 });

    // show the error per second in grafana
    if (checkRes === false ){
        errors.add(1);
    }
    sleep(waittime[Math.floor(Math.random() * waittime.length)]);



    let file_name="test"+makeid(6);
    let data = {
      inputFile: http.file(binFile, file_name+'.jpg'),
    };

    let res = session.post('/upload', data);
    let checkResupload = check(res, { "status is 201": (r) => r.status === 201 });

    // show the error per second in grafana
    if (checkResupload === false ){
        errors.add(1);
    }
    sleep(waittime[Math.floor(Math.random() * waittime.length)]);


}

 export function teardown(){
      // Cleanly shutdown and flush telemetry when k6 exits.
     // tracing.shutdown();
    }