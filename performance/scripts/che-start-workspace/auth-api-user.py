import json, os, threading
from locust import HttpLocust, TaskSet, task
from datetime import datetime

serverScheme = "@@SERVER_SCHEME@@"
serverHost = "@@SERVER_HOST@@"
authPort = "@@AUTH_PORT@@"
cheServerUrl = "@@CHE_SERVER_URL@@"

_users = -1
_userTokens = []
_userRefreshTokens = []
_currentUser = 0
_userLock = threading.RLock()

usenv = os.getenv("USER_TOKENS")
lines = usenv.split('\n')

_users = len(lines)

for u in lines:
	up = u.split(';')
	_userTokens.append(up[0])
	_userRefreshTokens.append(up[1])

class TokenBehavior(TaskSet):

	taskUser = -1
	taskUserId = ""
	taskUserName = ""
	taskUserToken = ""
	taskUserRefreshToken = ""

	def on_start(self):
		global _currentUser, _users, _userLock, _userTokens, _userRefreshTokens
		_userLock.acquire()
		self.taskUser = _currentUser
		if _currentUser < _users - 1:
			_currentUser += 1
		else:
			_currentUser = 0
		_userLock.release()
		self.taskUserToken = _userTokens[self.taskUser]
		self.taskUserRefreshToken = _userRefreshTokens[self.taskUser]

	@task
	def createStartDeleteWorkspace(self):
		id = self.createWorkspace()
		print "TEST id="+id
		self.wait()
		self.startWorkspace(id)
		self.wait()
		self.waitForWorkspaceToStart(id)
		self.stopWorkspace(id)
		self.wait()
		self.deleteWorkspace(id)

	def createWorkspace(self):
		print "Creating workspace"
		json_data=open("/home/rhopp/git/fabric8-auth-tests/performance/scripts/che-start-workspace/body.json").read()
		print "Token:"
		print self.taskUserToken
		response = self.client.post("/api/workspace", headers = {"Authorization" : "Bearer " + self.taskUserToken, "Content-Type":"application/json"}, name = "createWorkspace", data = json_data, catch_response = True)
		print "============"
		print response.content
		print response.json()
		print "============"
		try:
			resp_json = response.json()
			print resp_json
			if not response.ok:
				response.failure("Got wrong response: [" + response.content + "]")
			else:
				response.success()
				return resp_json["id"]
		except ValueError:
			response.failure("Got wrong response: [" + response.content + "]")

	def startWorkspace(self, id):
		print "Starting workspace id "+id
		response = self.client.post("/api/workspace/"+id+"/runtime", headers = {"Authorization" : "Bearer " + self.taskUserToken}, name = "startWorkspace", catch_response = True)
		try:
			content = response.content
			if not response.ok:
				response.failure("Got wrong response: [" + content + "]")
			else:
				response.success()
		except ValueError:
			response.failure("Got wrong response: [" + content + "]")

	def waitForWorkspaceToStart(self, id):
		while self.getWorkspaceStatus(id) != "RUNNING":
			print "Workspace id "+id+" is still not in state RUNNING"
			self.wait()
		print "Workspace id "+id+" is RUNNING"

	def stopWorkspace(self, id):
		print "Stopping workspace id "+id
		response = self.client.delete("/api/workspace/"+id+"/runtime", headers = {"Authorization" : "Bearer " + self.taskUserToken}, name = "stopWorkspace", catch_response = True)
		try:
			content = response.content
			if not response.ok:
				response.failure("Got wrong response: [" + content + "]")
			else:
				response.success()
		except ValueError:
			response.failure("Got wrong response: [" + content + "]")

	def deleteWorkspace(self, id):
		print "Deleting workspace id "+id
		response = self.client.delete("/api/workspace/"+id, headers = {"Authorization" : "Bearer " + self.taskUserToken}, name = "deleteWorkspace", catch_response = True)
		try:
			content = response.content
			if not response.ok:
				response.failure("Got wrong response: [" + content + "]")
			else:
				response.success()
		except ValueError:
			response.failure("Got wrong response: [" + content + "]")

	def getWorkspaceStatus(self, id):
		response = self.client.get("/api/workspace/"+id, headers = {"Authorization" : "Bearer " + self.taskUserToken}, name = "getWorkspaceStatus", catch_response = True)
		try:
			resp_json = response.json()
			content = response.content
			if not response.ok:
				response.failure("Got wrong response: [" + content + "]")
			else:
				response.success()
				return resp_json["status"]
		except ValueError:
			response.failure("Got wrong response: [" + content + "]")
			

class TokenUser(HttpLocust):
	host = cheServerUrl
	task_set = TokenBehavior
	min_wait = 1000
	max_wait = 10000
