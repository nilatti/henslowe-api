import API from './api'
import axios from 'axios';

let base_api = axios.create({
  baseURL: 'http://localhost:3001/'
})

async function createUser(user) {
  return (base_api.post(
    'users', {
      user
    }
  ))
}

async function deleteUser(userId) {
  return API.delete(`users/${userId}`)
}

async function getUser(userId) {
  return API.request(`users/${userId}`)
}

async function getUsers() {
  return API.request(`users`)
}

async function updateServerUser(user) {
  return API.put(`users/${user.id}`, {
    id: user.id,
    user: user,
  })
}


export {
  createUser,
  deleteUser,
  getUser,
  getUsers,
  updateServerUser
}