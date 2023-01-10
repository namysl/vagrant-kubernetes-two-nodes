import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '20m', target: 600 },
    { duration: '10m', target: 600 },
    { duration: '5m', target: 800 },
    { duration: '10m', target: 200 },
    { duration: '2m', target: 0 },
    { duration: '3m', target: 1000 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 100 },
    { duration: '3m', target: 0 }
  ],
};

export default function () {
  http.get('http://192.168.49.2:30001');
  sleep(1);
}

