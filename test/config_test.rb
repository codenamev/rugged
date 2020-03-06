require "test_helper"

class ConfigTest < Rugged::TestCase
  def setup
    @repo = FixtureRepo.from_rugged("testrepo.git")
  end

  def test_multi_fetch
    config = @repo.config
    fetches = ["+refs/heads/*:refs/remotes/test_remote/*",
               "+refs/heads/*:refs/remotes/hello_remote/*"]
    assert_equal fetches, config.get_all("remote.test_multiple_fetches.fetch")
  end

  def test_read_config_file
    config = @repo.config
    assert_equal 'false', config['core.bare']
    assert_nil config['not.exist']
  end

  def test_read_config_from_path
    config = Rugged::Config.new(File.join(@repo.path, 'config'))
    assert_equal 'false', config['core.bare']
  end

  def test_read_global_config_file
    config = Rugged::Config.global
    refute_nil config['user.name']
    assert_nil config['core.bare']
  end

  def test_snapshot
    config = Rugged::Config.new(File.join(@repo.path, 'config'))
    config['old.value'] = 5

    snapshot = config.snapshot
    assert_equal '5', snapshot['old.value']

    config['new.value'] = 42
    config['old.value'] = 1337

    assert_equal '5', snapshot['old.value']
    assert_nil snapshot['new.value']
  end

  def test_transaction
    config = Rugged::Config.new(File.join(@repo.path, 'config'))
    config['section.name'] = 'value'

    config2 = Rugged::Config.new(File.join(@repo.path, 'config'))

    config.transaction do
      config['section.name'] = 'other value'
      config['section2.name3'] = 'more value'

      assert_equal 'value', config2['section.name']
      assert_nil config2['section2.name3']

      assert_equal 'value', config['section.name']
      assert_nil config['section2.name3']
    end

    assert_equal 'other value', config['section.name']
    assert_equal 'more value', config['section2.name3']
    assert_equal 'other value', config2['section.name']
    assert_equal 'more value', config2['section2.name3']
  end
end

class ConfigWriteTest < Rugged::TestCase
  def setup
    @source_repo = FixtureRepo.from_rugged("testrepo.git")
    @repo = FixtureRepo.clone(@source_repo)
    @path = @repo.workdir
  end

  def test_write_config_values
    config = @repo.config
    config['custom.value'] = 'my value'

    config2 = @repo.config
    assert_equal 'my value', config2['custom.value']

    content = File.read(File.join(@repo.path, 'config'))
    assert_match(/value = my value/, content)
  end

  def test_write_multivar_config_values
    config = @repo.config
    config.add('custom.multivalue', 'my value')
    config.add('custom.multivalue', true)
    config.add('custom.multivalue', 42)

    config2 = @repo.config
    custom_multivar = ['my value', 'true', '42']
    assert_equal custom_multivar, config2.get_all('custom.multivalue')

    content = File.read(File.join(@repo.path, 'config'))
    assert_match(/multivalue = my value/, content)
    assert_match(/multivalue = true/, content)
    assert_match(/multivalue = 42/, content)
  end

  def test_delete_config_values
    config = @repo.config
    config.delete('core.bare')

    config2 = @repo.config
    assert_nil config2.get('core.bare')
  end
end
