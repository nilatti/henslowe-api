import PropTypes from 'prop-types';
import React, {
  Component
} from 'react'
import {
  Button,
  Col,
  Form,
} from 'react-bootstrap'
import {
  Typeahead
} from 'react-bootstrap-typeahead';

import {
  getCharacters
} from '../../../../../api/plays'

class FrenchSceneForm extends Component {
  constructor(props) {
    super(props)
    this.state = {
      available_characters: [],
      end_page: this.props.french_scene.end_page,
      number: this.props.french_scene.number,
      scene_id: this.props.scene_id,
      selected_characters: this.props.french_scene.characters || [],
      start_page: this.props.french_scene.start_page,
      summary: this.props.french_scene.summary,
      validated: false,
    }
  }

  componentDidMount = () => {
    this.loadCharactersFromServer()
  }

  handleChange = (event) => {
    this.setState({
      [event.target.name]: event.target.value
    })
  }

  handleCharactersChange = (selected) => {
    console.log('characters change caled')
    this.setState({
      selected_characters: selected
    })
  }

  handleSubmit = (event) => {
    const form = event.currentTarget;
    if (form.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
    } else {
      this.processSubmit()
    }
    this.setState({
      validated: true
    })
  }

  processSubmit = () => {
    console.log('inside process', this.state.selected_characters)
    var character_ids = this.state.selected_characters.map((character) => character.id)
    var characters = this.state.available_characters.filter(character => character_ids.includes(character.id))
    this.props.onFormSubmit({
      character_ids: character_ids,
      characters: characters,
      end_page: this.state.end_page,
      id: this.props.french_scene.id,
      number: this.state.number,
      on_stages: this.props.french_scene.on_stages,
      scene_id: this.state.scene_id,
      start_page: this.state.start_page,
      summary: this.state.summary,
    })
  }

  async loadCharactersFromServer() {
    const response = await getCharacters(this.props.play_id)
    if (response.status >= 400) {
      this.setState({
        errorStatus: 'Error fetching characters'
      })
    } else {
      this.setState({
        available_characters: response.data
      })
    }
  }

  render() {
    if (!this.state.available_characters) {
      return <div>Loading characters</div>
    }

    var available_characters = this.state.available_characters.map((character) => ({
      id: character.id,
      label: String(character.name)
    }))

    var selected_characters = this.state.selected_characters.map((character) => ({
      id: character.id,
      label: String(character.name)
    }))
    const {
      validated
    } = this.state
    return (
      <Col md={{ span: 8, offset: 2 }}>
        <Form
          noValidate
          onSubmit={e => this.handleSubmit(e)}
          validated={validated}
        >

          <Form.Row>
            <Col>
            <Form.Group controlId="number">
              <Form.Label>
                French Scene Number (letter)
              </Form.Label>
              <Form.Control
                type="text"
                placeholder="french scene number"
                name="number"
                onChange={this.handleChange}
                pattern="[a-z]+"
                required
                value={this.state.number}
              />
              <Form.Control.Feedback type="invalid">
                French scene "number" is required, and must be lowercase letters (sorry).
              </Form.Control.Feedback>
            </Form.Group>
            </Col>
            <Col>
              <Form.Group controlId="start_page">
                  <Form.Label>
                    Start Page
                  </Form.Label>
                    <Form.Control
                      type="number"
                      placeholder="starting page number"
                      name="start_page"
                      onChange={this.handleChange}
                      pattern="[0-9]+"
                      value={this.state.start_page}
                    />
                </Form.Group>
              </Col>
              <Col>
              <Form.Group controlId="end_page">
                  <Form.Label>
                    End Page
                  </Form.Label>
                    <Form.Control
                      type="number"
                      placeholder="ending page number"
                      name="end_page"
                      onChange={this.handleChange}
                      pattern="[0-9]+"
                      value={this.state.end_page}
                    />
                </Form.Group>
              </Col>
          </Form.Row>
          <Form.Row>
          <Typeahead
            defaultSelected={selected_characters}
            id="characters"
            multiple={true}
            options={available_characters}
            onChange={(selected) => {
              this.handleCharactersChange(selected)
            }}
            placeholder="Select the characters that are in the scene..."
          />
          </Form.Row>
          <Form.Group controlId="summary">
            <Form.Label>
              Summary
            </Form.Label>
            <Form.Control
              as="textarea"
              rows="10"
              placeholder="summary"
              name="summary"
              value={this.state.summary}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Button type="submit" variant="primary" block>Submit</Button>
          <Button type="button" onClick={this.props.onFormClose} block>Cancel</Button>
        </Form>
        <hr />
      </Col>
    )
  }
}

FrenchSceneForm.defaultProps = {
  french_scene: {
    number: '',
    summary: ''
  }
}

FrenchSceneForm.propTypes = {
  french_scene: PropTypes.object,
  onFormClose: PropTypes.func.isRequired,
  onFormSubmit: PropTypes.func.isRequired,
  scene_id: PropTypes.number.isRequired,
  play_id: PropTypes.number.isRequired,
}

export default FrenchSceneForm