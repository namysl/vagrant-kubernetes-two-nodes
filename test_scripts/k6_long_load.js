import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '3m', target: 50 },
    { duration: '10m', target: 200 },
    { duration: '10m', target: 300 },
    { duration: '10m', target: 100 },
    { duration: '5m', target: 50 },
    { duration: '2m', target: 10 },
    { duration: '10m', target: 0 },
  ],
};

export default function () {
  http.get('http://192.168.49.2:30001');
  sleep(1);
}
