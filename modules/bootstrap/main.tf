# S3 bucket for Palo Alto VM-Series bootstrap configuration
resource "aws_s3_bucket" "bootstrap_bucket" {
  bucket = var.bucket_name
  force_destroy = true  # Allow terraform to destroy non-empty bucket

  tags = {
    Name = "palo-alto-bootstrap-bucket"
  }
}

# Block public access to the bootstrap bucket
resource "aws_s3_bucket_public_access_block" "bootstrap_bucket_access" {
  bucket = aws_s3_bucket.bootstrap_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "bootstrap_bucket_ownership" {
  bucket = aws_s3_bucket.bootstrap_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Create the config directory
resource "aws_s3_object" "init_cfg" {
  bucket = aws_s3_bucket.bootstrap_bucket.id
  key    = "config/init-cfg.txt"
  content = <<-EOF
type=dhcp-client
op-command-modes=jumbo-frame,mgmt-interface-swap
bootstrap-interfaces=mgmt
dhcp-accept-server-hostname=yes
dhcp-accept-server-domain=yes
dns-primary=8.8.8.8
dns-secondary=8.8.4.4
dhcp-send-hostname=yes
dhcp-send-client-id=yes
ipv6-disable=yes
plugin-op-commands=aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable
EOF
}

# Create a more complete bootstrap.xml configuration for standalone firewalls
resource "aws_s3_object" "bootstrap_xml" {
  bucket = aws_s3_bucket.bootstrap_bucket.id
  key    = "config/bootstrap.xml"
  content = <<-EOF
<?xml version="1.0"?>
<config version="11.1.0" urldb="paloaltonetworks">
  <mgt-config>
    <users>
      <entry name="admin">
        <phash>$1$vdorswqa$PAHfUYkrPQmKbeEae6/.1/</phash>
        <permissions>
          <role-based>
            <superuser>yes</superuser>
          </role-based>
        </permissions>
      </entry>
    </users>
  </mgt-config>
  <shared>
    <application/>
    <application-group/>
    <service/>
    <service-group/>
    <botnet>
      <configuration>
        <http>
          <dynamic-dns>
            <enabled>yes</enabled>
            <threshold>5</threshold>
          </dynamic-dns>
          <malware-sites>
            <enabled>yes</enabled>
            <threshold>5</threshold>
          </malware-sites>
        </http>
      </configuration>
    </botnet>
  </shared>
  <devices>
    <entry name="localhost.localdomain">
      <network>
        <interface>
          <ethernet>
            <entry name="ethernet1/1">
              <layer3>
                <dhcp-client>
                  <enable>yes</enable>
                  <create-default-route>no</create-default-route>
                </dhcp-client>
                <mtu>9192</mtu>
                <interface-management-profile>allow-mgmt-profile</interface-management-profile>
              </layer3>
            </entry>
            <entry name="ethernet1/2">
              <layer3>
                <dhcp-client>
                  <enable>yes</enable>
                </dhcp-client>
                <mtu>9192</mtu>
                <interface-management-profile>allow-mgmt-profile</interface-management-profile>
              </layer3>
            </entry>
          </ethernet>
        </interface>
        <profiles>
          <interface-management-profile>
            <entry name="mgmt">
              <https>yes</https>
              <ssh>yes</ssh>
              <ping>yes</ping>
            </entry>
            <entry name="allow-mgmt-profile">
              <ping>yes</ping>
              <ssh>yes</ssh>
              <https>yes</https>
            </entry>
          </interface-management-profile>
        </profiles>
        <virtual-router>
          <entry name="default">
            <interface>
              <member>ethernet1/1</member>
              <member>ethernet1/2</member>
            </interface>
            <ecmp>
              <algorithm>
                <ip-modulo/>
              </algorithm>
            </ecmp>
            <protocol>
              <bgp>
                <routing-options>
                  <graceful-restart>
                    <enable>yes</enable>
                  </graceful-restart>
                </routing-options>
                <enable>no</enable>
              </bgp>
              <rip>
                <enable>no</enable>
              </rip>
              <ospf>
                <enable>no</enable>
              </ospf>
              <ospfv3>
                <enable>no</enable>
              </ospfv3>
            </protocol>
            <routing-table>
              <ip>
                <static-route>
                  <entry name="internal-routes">
                    <nexthop>
                      <ip-address>10.11.2.1</ip-address>
                    </nexthop>
                    <bfd>
                      <profile>None</profile>
                    </bfd>
                    <interface>ethernet1/1</interface>
                    <metric>10</metric>
                    <destination>10.0.0.0/8</destination>
                    <route-table>
                      <unicast/>
                    </route-table>
                  </entry>
                </static-route>
              </ip>
            </routing-table>
          </entry>
        </virtual-router>
      </network>
      <deviceconfig>
        <system>
          <type>
            <dhcp-client>
              <send-hostname>yes</send-hostname>
              <send-client-id>yes</send-client-id>
              <accept-dhcp-hostname>yes</accept-dhcp-hostname>
              <accept-dhcp-domain>yes</accept-dhcp-domain>
            </dhcp-client>
          </type>
          <update-server>updates.paloaltonetworks.com</update-server>
          <update-schedule>
            <threats>
              <recurring>
                <weekly>
                  <day-of-week>wednesday</day-of-week>
                  <at>01:02</at>
                </weekly>
              </recurring>
            </threats>
          </update-schedule>
          <timezone>US/Pacific</timezone>
          <service>
            <disable-telnet>yes</disable-telnet>
            <disable-http>yes</disable-http>
          </service>
          <hostname>paloalto-firewall</hostname>
          <dns-setting>
            <servers>
              <primary>8.8.8.8</primary>
              <secondary>8.8.4.4</secondary>
            </servers>
          </dns-setting>
        </system>
        <setting>
          <management>
            <initcfg>
              <dns-secondary>8.8.4.4</dns-secondary>
              <dns-primary>8.8.8.8</dns-primary>
              <op-command-modes>jumbo-frame,mgmt-interface-swap</op-command-modes>
              <type>
                <dhcp-client>
                  <send-hostname>yes</send-hostname>
                  <send-client-id>yes</send-client-id>
                  <accept-dhcp-hostname>yes</accept-dhcp-hostname>
                  <accept-dhcp-domain>yes</accept-dhcp-domain>
                </dhcp-client>
              </type>
            </initcfg>
          </management>
          <config>
            <rematch>yes</rematch>
          </config>
        </setting>
      </deviceconfig>
      <vsys>
        <entry name="vsys1">
          <application/>
          <application-group/>
          <zone>
            <entry name="inspect">
              <network>
                <layer3>
                  <member>ethernet1/1</member>
                </layer3>
              </network>
            </entry>
            <entry name="outside">
              <network>
                <layer3>
                  <member>ethernet1/2</member>
                </layer3>
              </network>
            </entry>
          </zone>
          <service/>
          <service-group/>
          <schedule/>
          <rulebase>
            <security>
              <rules>
                <entry name="Allow outbound" uuid="c1e68692-f0f4-4c47-b0fe-9e3a903b86e6">
                  <to>
                    <member>outside</member>
                  </to>
                  <from>
                    <member>inspect</member>
                  </from>
                  <source>
                    <member>any</member>
                  </source>
                  <destination>
                    <member>any</member>
                  </destination>
                  <service>
                    <member>application-default</member>
                  </service>
                  <application>
                    <member>any</member>
                  </application>
                  <action>allow</action>
                  <log-end>yes</log-end>
                </entry>
                <entry name="inspect-traffic" uuid="6403ff18-6e15-41c2-a324-476e3a50c00d">
                  <to>
                    <member>inspect</member>
                  </to>
                  <from>
                    <member>inspect</member>
                  </from>
                  <source>
                    <member>any</member>
                  </source>
                  <destination>
                    <member>any</member>
                  </destination>
                  <source-user>
                    <member>any</member>
                  </source-user>
                  <category>
                    <member>any</member>
                  </category>
                  <application>
                    <member>any</member>
                  </application>
                  <service>
                    <member>application-default</member>
                  </service>
                  <source-hip>
                    <member>any</member>
                  </source-hip>
                  <destination-hip>
                    <member>any</member>
                  </destination-hip>
                  <action>allow</action>
                  <log-start>yes</log-start>
                  <log-end>yes</log-end>
                </entry>
              </rules>
            </security>
            <nat>
              <rules>
                <entry name="Outbound NAT" uuid="b9e6d336-1e6d-4a3f-a4c9-08cc5b49a604">
                  <to>
                    <member>outside</member>
                  </to>
                  <from>
                    <member>inspect</member>
                  </from>
                  <source>
                    <member>any</member>
                  </source>
                  <destination>
                    <member>any</member>
                  </destination>
                  <service>any</service>
                  <source-translation>
                    <dynamic-ip-and-port>
                      <interface-address>
                        <interface>ethernet1/2</interface>
                      </interface-address>
                    </dynamic-ip-and-port>
                  </source-translation>
                </entry>
              </rules>
            </nat>
            <default-security-rules>
              <rules>
                <entry name="intrazone-default" uuid="b68d0dfb-a4c2-4e46-aa6f-6ee1a382c66f">
                  <action>allow</action>
                  <log-start>yes</log-start>
                  <log-end>yes</log-end>
                </entry>
              </rules>
            </default-security-rules>
          </rulebase>
          <import>
            <network>
              <interface>
                <member>ethernet1/1</member>
                <member>ethernet1/2</member>
              </interface>
            </network>
          </import>
        </entry>
      </vsys>
    </entry>
  </devices>
</config>
EOF
}

# Create empty directories for other bootstrap components
resource "aws_s3_object" "config_dir" {
  bucket = aws_s3_bucket.bootstrap_bucket.id
  key    = "config/"
  content = ""
}

resource "aws_s3_object" "content_dir" {
  bucket = aws_s3_bucket.bootstrap_bucket.id
  key    = "content/"
  content = ""
}

resource "aws_s3_object" "license_dir" {
  bucket = aws_s3_bucket.bootstrap_bucket.id
  key    = "license/"
  content = ""
}

resource "aws_s3_object" "software_dir" {
  bucket = aws_s3_bucket.bootstrap_bucket.id
  key    = "software/"
  content = ""
}
