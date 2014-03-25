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

def http_request(url, proto=nil)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri.request_uri)
  req['X-Forwarded-Proto'] = proto if proto
  Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}
end

describe 'http://docs.balancedpayments.com' do
  it 'should redirect to HTTPS' do
    res = http_request('http://localhost/index.html')
    expect(res.code).to eq('301')
    expect(res['Location']).to eq('https://localhost/index.html')
  end

  it 'should redirect to HTTPS (explicit x-forwarded-proto)' do
    res = http_request('http://localhost/index.html', 'http')
    expect(res.code).to eq('301')
    expect(res['Location']).to eq('https://localhost/index.html')
  end

  it 'should support the health check' do
    res = http_request('http://localhost/__health__')
    expect(res.code).to eq('200')
    expect(res.body).to eq('ok')
  end
end

describe 'https://docs.balancedpayments.com' do
  it '1.1 should work' do
    res = http_request('http://localhost/1.1/overview/resources/', 'https')
    expect(res.code).to eq('200')
    expect(res.body).to include('Test credit card numbers')
  end
  
  it '1.0 should work' do
    res = http_request('http://localhost/1.0/overview/resources/', 'https')
    expect(res.code).to eq('200')
    expect(res.body).to include('Test credit card numbers')
  end

  it 'should redirect from / to /1.1/overview/' do
    res = http_request('http://localhost/', 'https')
    expect(res.code).to eq('301')
    expect(res['Location']).to eq('https://localhost/1.1/overview/')
  end

  it 'should redirect from /api/ to /1.1/api/' do
    res = http_request('http://localhost/api/', 'https')
    expect(res.code).to eq('301')
    expect(res['Location']).to eq('https://localhost/1.1/api/')
  end

  it 'should serve static assets' do
    res = http_request('http://localhost/static/css/styles.css', 'https')
    expect(res.code).to eq('200')
  end

  it 'should redirect 404s to the overview' do
    res = http_request('http://localhost/1.0/notfound', 'https')
    expect(res.code).to eq('301')
    expect(res['Location']).to eq('https://localhost/1.1/overview/')
  end
end
