import http from 'k6/http'
import { check } from 'k6'

export const options = {
  stages: [
    { duration: '30s', target: 10 }, // warm up stage, ramp up to target VUs
    { duration: '5m', target: 10 } // stress stage, hold at target
  ]
}

const adminEmail = 'user@rokkincat.com'
const adminPassword = 'password'
const host = 'http://0.0.0.0:4000'

const baseOptions = {
  headers: {
    'Accept-Encoding': 'gzip',
    'Content-Type': 'application/json'
  }
}

const getSessionToken = (email, password) => {
  const payload = JSON.stringify({
    session: {
      email: email,
      password: password
    }
  })

  const res = http.post(
    `${host}/api/sessions`,
    payload,
    baseOptions
  )

  return {
    id: JSON.parse(res.body).data.id,
    token: res.headers.Authorization
  }
}

const createPoint = (token) => {
  const payload = JSON.stringify({
    location: [
      {
        activity: { confidence: 100, type: 'still' },
        battery: { is_charging: true, level: 0.91 },
        coords: {
          accuracy: 52,
          altitude: 22.1,
          altitude_accuracy: 107.7,
          heading: 0.35,
          heading_accuracy: -1,
          latitude: 43,
          longitude: -89,
          speed: 0,
          speed_accuracy: -1
        },
        extras: {
          shift_id: null,
          status: 'working',
          trip_id: null,
          user_id: 4401 // ignored
        },
        is_moving: false,
        odometer: 7468123,
        timestamp: (new Date()).toISOString(),
        uuid: 'df4330e6-d1f1-4df7-80c5-7e6c49940898'
      }
    ]
  })

  const options = {
    headers: {
      'Accept-Encoding': 'gzip',
      Authorization: token,
      'Content-Type': 'application/json'
    }
  }

  return http.post(`${host}/api/points`, payload, options)
}

const acceptTerms = (token, termsId) => {
  const payload = JSON.stringify({
    accepted_terms: {
      terms_id: termsId
    }
  })

  const options = {
    headers: {
      'Accept-Encoding': 'gzip',
      Authorization: token,
      'Content-Type': 'application/json'
    }
  }

  return http.post(`${host}/api/accepted_terms`, payload, options)
}

const getPayPerformanceStats = (token, userId) => {
  const options = {
    headers: {
      'Accept-Encoding': 'gzip',
      Authorization: token,
      'Content-Type': 'application/json'
    }
  }

  return http.get(`${host}/api/user_pay_performance/${userId}`, options)
}

const getDailyStatsExport = (token) => {
  const options = {
    headers: {
      'Accept-Encoding': 'gzip',
      Authorization: token,
      'Content-Type': 'application/json'
    }
  }

  return http.get(`${host}/api/_admin/export/daily_stats`, options)
}

const checkStatus = (r) => r.status === 200 || r.status === 201

export default function () {
  const { token: adminToken } = getSessionToken(adminEmail, adminPassword)
  const res = createPoint(adminToken)
  check(res, { 'point creation status was ok': checkStatus })
}
