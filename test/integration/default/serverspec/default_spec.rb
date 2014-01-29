#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2014, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'net/http'
require 'uri'

require 'serverspec'
include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe service('nginx') do
  it { should be_running }
end

describe port(80) do
  it { should be_listening }
end

describe 'http://docs.balancedpayments.com' do
  it 'should redirect to HTTPS' do
    res = Net::HTTP.get(URI('http://localhost/index.html'))
    expect(res.code).to eq(302)
    expect(res['Location']).to eq('https://localhost/index.html')
  end

  it 'should redirect to HTTPS (explicit x-forwarded-proto)' do
    uri = URI('http://localhost/index.html')
    req = Net::HTTP::Get.new(uri.request_uri)
    req['X-Forwarded-Proto'] = 'http'
    res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}
    expect(res.code).to eq(302)
    expect(res['Location']).to eq('https://localhost/index.html')
  end
end

describe 'https://docs.balancedpayments.com' do
  it 'should work' do
    uri = URI('http://localhost/1.1/overview/resources/')
    req = Net::HTTP::Get.new(uri.request_uri)
    req['X-Forwarded-Proto'] = 'https'
    res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}
    expect(res.code).to eq(200)
  end
end
