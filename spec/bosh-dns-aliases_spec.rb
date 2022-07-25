require 'rspec'
require 'json'
require 'yaml' # todo fix bosh-template
require 'bosh/template/test'

describe 'bosh-dns-aliases job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '..')) }
  let(:job) { release.job('bosh-dns-aliases') }

  describe 'aliases.json template' do
    let(:template) { job.template('dns/aliases.json') }

    it 'canonicalizes DNS labels' do
      tpl_output = template.render({
        'aliases' => [{
          'domain' => 'credhub.cf.internal',
          'targets' => [{
            'query' => '*',
            'instance_group' => 'diego_cell1',
            'deployment' => 'cf_1',
            'network' => 'default_123',
            'domain' => 'bosh1',
          },{
            'query' => '*',
            'instance_group' => 'diego_cell2',
            'deployment' => 'cf_2',
            'network' => 'default',
            'domain' => 'bosh2',
          }]
        }]
      })

      expect(JSON.parse(tpl_output)).to eq({
        "credhub.cf.internal" => [
          "*.diego-cell1.default-123.cf-1.bosh1",
          "*.diego-cell2.default.cf-2.bosh2",
        ]
      })
    end

    it 'raises error if targets are not present' do
      expect {
        tpl_output = template.render({
          'aliases' => [{
            'domain' => 'credhub.cf.internal',
          }]
        })
      }.to raise_error /key not found: "targets"/
    end

    it 'raises error if domain is not present' do
      expect {
        tpl_output = template.render({
          'aliases' => [{}]
        })
      }.to raise_error /key not found: "domain"/
    end

    it 'uses spec.dns_domain_name by default if target domain is not specified' do
      class CustomInstanceSpec < Bosh::Template::Test::InstanceSpec
        def to_h
          super.to_h.merge("dns_domain_name" => "default-domain")
        end
      end

      tpl_output = template.render({
        'aliases' => [{
          'domain' => 'credhub.cf.internal',
          'targets' => [{
            'query' => '*',
            'instance_group' => 'diego_cell1',
            'deployment' => 'cf_123',
            'network' => 'default_123',
          },{
            'query' => '*',
            'instance_group' => 'diego_cell2',
            'deployment' => 'cf_123',
            'network' => 'default',
            'domain' => 'non-default-bosh',
          }]
        }]
      }, spec: CustomInstanceSpec.new)

      expect(JSON.parse(tpl_output)).to eq({
        "credhub.cf.internal" => [
          "*.diego-cell1.default-123.cf-123.default-domain",
          "*.diego-cell2.default.cf-123.non-default-bosh",
        ]
      })
    end

    it 'canonicalizes by all of special rules' do
      tpl_output = template.render({
        'aliases' => [{
          'domain' => 'credhub.cf.internal',
          'targets' => [{
            'query' => '*',
            'instance_group' => 'Diego_cell1^.', # uppercase, _, special char
            'deployment' => 'Cf_1^.',
            'network' => 'Default_123^.',
            'domain' => 'bosh1^', # not canonicalized
          }]
        }]
      })

      expect(JSON.parse(tpl_output)).to eq({
        "credhub.cf.internal" => [
          "*.diego-cell1.default-123.cf-1.bosh1^",
        ]
      })
    end

    it 'keeps wildcard "*" identifier as is' do
      tpl_output = template.render({
        'aliases' => [{
          'domain' => 'credhub.cf.internal',
          'targets' => [{
            'query' => '*',
            'instance_group' => '*Die*go_cell1^.*', # uppercase, _, special char
            'deployment' => '*C*f_1^.*',
            'network' => '*Defau*lt_123^.*',
            'domain' => 'bosh1^', # not canonicalized
          }]
        }]
      })

      expect(JSON.parse(tpl_output)).to eq({
        "credhub.cf.internal" => [
          "*.*die*go-cell1*.*defau*lt-123*.*c*f-1*.bosh1^",
        ]
      })
    end
  end
end
